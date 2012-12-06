package editor.ui
{
	import pixel.ui.control.UIContainer;
	import corecom.control.HorizontalPanel;
	import corecom.control.IUIControl;
	import pixel.ui.control.UIButton;
	import pixel.ui.control.UIPanel;
	import pixel.ui.control.SimpleTabPanel;
	import pixel.ui.control.UIControl;
	import pixel.ui.control.UIVerticalPanel;
	import pixel.ui.control.event.ControlEditModeEvent;
	import pixel.ui.control.utility.Utils;
	
	import editor.code.ClassFactory;
	import editor.code.ComponentClass;
	import editor.event.NotifyEvent;
	import editor.model.ComponentModel;
	import editor.model.ModelFactory;
	import editor.uitility.ui.event.UIEvent;
	
	import flash.desktop.NativeProcess;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.EventPhase;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.utils.StringUtil;
	
	import spark.components.Group;
	
	import utility.IDispose;
	import utility.Tools;
	
	/**
	 * 
	 * 工作区容器
	 * 因为要用到sprite的组件,所以增加一个容器进行组件管理
	 * 
	 **/
	public class WorkspaceWAK extends UIComponent implements IDispose
	{
		//private var CurrentActived:Sprite = null;
		private var _Children:Array = [];
		//新创建组件的基本信息
		private var _ComponentProfile:ComponentProfile = null;
		private var _Container:Shell = null;
		private var _ContainerControl:UIControl = null;
		
		//是否复合组件
		private var IsComplex:Boolean = false;
		
		private var _ConstructTree:Array = [];
		
		private var _ContainerNode:TreeNode = null;
		
		//private var _NodeMap:Dictionary = new Dictionary();
		public function WorkspaceWAK(Profile:ComponentProfile = null)
		{
			if(Profile)
			{
				BuildWorkspace(Profile);
			}
			//this.addEventListener(MouseEvent.MOUSE_DOWN,OnSelectClick);
			this.addEventListener(ControlEditModeEvent.CHILDSELECTED,OnControlChildSelect);
			
		}
		
//		public function IsContainer(Item:Shell):Boolean
//		{
//			return Item == _Container;
//			
//		}
		public function IsContainer(Item:UIControl):Boolean
		{
			return Item == _Container;
			
		}
		
		public function get Children():Array
		{
			return _Children;
		}
		
		public function BuildWorkspace(Profile:ComponentProfile):void
		{
			if(Profile)
			{
				_ComponentProfile = Profile;
				if(_ComponentProfile.Category == 1)
				{
					IsComplex = true;
					//复合组件
					switch(_ComponentProfile.Container)
					{
						case 0:
							_Container = addChild(new UIPanel()) as Shell;
							_Container.Control.width = 500;
							_Container.Control.height = 500;
							_Container.graphics.clear();
							break;
						case 1:
							_Container = addChild(new HorizontalPanel()) as Shell;
							break;
						case 2:
							_Container = addChild(new UIVerticalPanel()) as Shell;
							break;
					}
					
					_ContainerControl = _Container.Control as UIControl;
				}
				else
				{
					var Prototype:Class = Utils.GetPrototypeByType(_ComponentProfile.Component);
					var Control:UIControl = new Prototype() as UIControl;
					Control.width = 200;
					Control.height = 80;
					if(Prototype)
					{
						if(Control is SimpleTabPanel)
						{
							SimpleTabPanel(Control).CreateTab();
						}
						_Container = addChild(Control) as Shell;
					}
//					switch(_ComponentProfile.Component)
//					{
//						case 0:
//							_Container = addChild(new SimpleButton()) as Shell;
//							break;
//					}
				}
			}
		}
		
		public function get Component():UIControl
		{
			if(IsComplex)
			{
				return _Container.Control as UIControl;
			}
			else
			{
				return _Children[0] as UIControl;
			}
		}
		
		public function Dispose():void
		{
			if(_Container)
			{
				removeChild(_Container);
			}
			_Container = null;
			_ContainerControl = null;
			
			if(_Children && _Children.length > 0)
			{
				var Obj:DisplayObject = null;
				
				while(Obj = _Children.pop())
				{
					if(contains(Obj))
					{
						removeChild(Obj);
					}
				}
			}
			
			_Children = [];
		}
		
		private var _CurrentShell:Shell = null;
		
		private function OnControlChildSelect(event:ControlEditModeEvent):void
		{
			var Control:UIControl = event.Params.pop() as UIControl;
			if(Control)
			{
				if(_LastShell)
				{
					_LastShell.Disable();
				}
				_LastShell = event.target is UIControl ? ShellMap[event.target] : event.target as Shell;
				//_LastShell = event.target as Shell;
				
				var ChoiceNotify:NotifyEvent = new NotifyEvent(NotifyEvent.COMPONENT_SELECTED);
				ChoiceNotify.Params.push(Control);
				//ChoiceNotify.Params.push(Shell(Event.target).Control);
				dispatchEvent(ChoiceNotify);
				if(_LastShell)
				{
					_LastShell.Enable();
				}
			}
		}
		
		private var _LastShell:Shell = null;
		/**
		 * 子组件选择
		 **/
		private function OnSelectClick(event:MouseEvent):void
		{
			if(event.target is UIContainer || event.target is Shell)
			{
				if(_LastShell)
				{
					_LastShell.Disable();
				}
				_LastShell = event.target as Shell;
				var ChoiceNotify:NotifyEvent = new NotifyEvent(NotifyEvent.COMPONENT_SELECTED);
				ChoiceNotify.Params.push(event.target is UIControl ? event.target:Shell(event.target).Control);
				//ChoiceNotify.Params.push(Shell(Event.target).Control);
				dispatchEvent(ChoiceNotify);
				if(_LastShell)
				{
					_LastShell.Enable();
				}
			}
		}
		
		/**
		 * 自定义组件添加
		 **/
		public function AddComponent(child:ComponentModel):void
		{
			var Proxy:Shell = null;
			//var Notify:NotifyEvent = null;
			ComponentModel(child).Control.EnableEditMode();
			
			_ContainerNode = new TreeNode();
			_ContainerNode.label = Tools.ClassSimpleName(ComponentModel(child).Control);
			Proxy = new Shell(child);
			_Container.addChild(Proxy);
			_Children.push(Proxy);
			
			Proxy.graphics.clear();
			Proxy.EnableDrawable = true;
			Proxy.addEventListener(NotifyEvent.COMPONENT_DRAG_START,DragStart);
			UpdateContructTree();
			//return Proxy;
		}
		
		private var ShellMap:Dictionary = new Dictionary();
		override public function addChild(child:DisplayObject):DisplayObject
		{
			//var Component:ComponentBorder = new ComponentBorder(child as IUIControl);
			//只有当组件类型为复合组件,同时容器类型为普通面板才允许拖拽
			//var Node:TreeNode = null;
			var Proxy:Shell = null;
			//var Notify:NotifyEvent = null;
			UIControl(child).EnableEditMode();
			if(_Container)
			{
				var Drag:Boolean = IsComplex && _ComponentProfile.Container == 0 ? true:false;
				Proxy = new Shell(child,Drag);
//				if(Drag)
//				{
//					Proxy.addEventListener(NotifyEvent.COMPONENT_DRAG_START,DragStart);
//				}
				_Container.addChild(Proxy);
				_Children.push(Proxy);
			}
			else
			{
				_ContainerNode = new TreeNode();
				_ContainerNode.label = Tools.ClassSimpleName(child);
				Proxy = new Shell(child);
				super.addChild(Proxy);
				
				Proxy.graphics.clear();
				Proxy.EnableDrawable = false;
			}
			
			UpdateContructTree();
			
			if(IsComplex)
			{
				Proxy.addEventListener(NotifyEvent.COMPONENT_DRAG_START,DragStart);
			}
			
			ShellMap[child] = Proxy;
			
			return Proxy;
			//Proxy.addEventListener(NotifyEvent.SHELLSELECTED,ShellSelected);
		}
		
		public function UpdateContructTree():void
		{
			var RootNode:TreeNode = _ContainerNode;
			RootNode.children = [];
			var ChildNode:TreeNode = null;
			var ChildShell:Shell = null;
			var ChildControl:UIControl = null;
			for(var Idx:int; Idx<_Children.length; Idx++)
			{
				ChildShell = _Children[Idx];
				ChildControl = ChildShell.Control as UIControl;
				ChildNode = new TreeNode();
				ChildNode.label = Tools.ClassSimpleName(ChildControl);
				ChildNode.Data = ChildShell;
				if(ChildControl is UIContainer)
				{
					ChildNode.children = GetChildTreeNode(ChildControl as UIContainer);
				}
				RootNode.children.push(ChildNode);
			}
			
			var Notify:NotifyEvent = new NotifyEvent(NotifyEvent.UPDATECONSTRUCT);
			Notify.Params.push([RootNode]);
			dispatchEvent(Notify);
//			var RootNode:TreeNode = _NodeMap[_Container];
//			if(RootNode)
//			{
//				var ChildrenNode:TreeNode = null;
//				for(var Idx:int=0; Idx<RootNode.children.length; Idx++)
//				{
//					ChildrenNode = RootNode.children[Idx];
//				}
//			}
		}
		
		private function GetChildTreeNode(Root:UIContainer):Array
		{
			var Nodes:Array = [];
			var Children:Array = Root.Children;
			for(var Idx:int=0; Idx<Children.length; Idx++)
			{
				var Node:TreeNode = new TreeNode();
				Node.label = Tools.ClassSimpleName(Children[Idx]);
				Node.Data = Children[Idx];
				Nodes.push(Node);
				
				if(Children[Idx] is UIContainer)
				{
					Node.children = GetChildTreeNode(Children[Idx] as UIContainer);
				}
			}
			return Nodes;
		}
		
//		private function ShellSelected(event:NotifyEvent):void
//		{
//			if(null != _CurrentShell)
//			{
//				_CurrentShell.graphics.clear();
//			}
//			_CurrentShell = event.target as Shell;
//		}
		
		private var OffsetX:int = 0;
		private var OffsetY:int = 0;
		private var DragTarget:DisplayObject = null;
		
		private function DragStart(event:NotifyEvent):void
		{
			if(_LastShell)
			{
				_LastShell.Disable();
			}
			_LastShell = event.Params.pop();
			_LastShell.Enable();
			var ChoiceNotify:NotifyEvent = new NotifyEvent(NotifyEvent.COMPONENT_SELECTED);
			ChoiceNotify.Params.push(_LastShell.Control);
			//ChoiceNotify.Params.push(Shell(Event.target).Control);
			dispatchEvent(ChoiceNotify);
			
			if(null != _CurrentShell)
			{
				_CurrentShell.graphics.clear();
//				if(_CurrentShell == _Container)
//				{
//					_Container.EnableDrawable = false;
//				}
			}
			_CurrentShell = event.target as Shell;
			//底层容器不允许拖拽
			if(event.target != _Container)
			{
				DragTarget = event.target as DisplayObject;
				//DragTarget.OnSelected();
				//DragTarget.BorderColor = 0xFF0000;
				//DragTarget.BorderThinkness = 2;
				OffsetX = event.Params.pop();
				OffsetY = event.Params.pop();
				stage.addEventListener(MouseEvent.MOUSE_MOVE,DragMove);
				stage.addEventListener(MouseEvent.MOUSE_UP,DragEnd);
			}
			else
			{
				//_Container.OnSelected();
			}
		}
		
		public function DeleteCurrentShell():void
		{
			if(_CurrentShell != _Container)
			{
				//delete _NodeMap[_CurrentShell];
				_Container.removeChild(_CurrentShell);
				_Children.splice(_Children.indexOf(_CurrentShell),1);
				UpdateContructTree();
			}
		}
		
		public function GetCurrentShell():Shell
		{
			return _CurrentShell;
		}
		
		private var TransPoint:Point = new Point();
		private var PosX:int = 0;
		private var PosY:int = 0;
		private function DragMove(Event:MouseEvent):void
		{
			TransPoint.x = Event.stageX;
			TransPoint.y = Event.stageY;
			TransPoint = _Container? _Container.globalToLocal(TransPoint):globalToLocal(TransPoint);
			PosX = TransPoint.x - OffsetX;
			PosY = TransPoint.y - OffsetY;
			if(PosX + DragTarget.width > (_Container.width))
			{
				PosX = _Container.width - DragTarget.width;
			}
			if(PosY + DragTarget.height > _Container.height)
			{
				PosY = _Container.height - DragTarget.height;
			}
			if(PosX < 0)
			{
				PosX = 0;
			}
			if(PosY < 0)
			{
				PosY = 0;
			}
			DragTarget.x = PosX;
			DragTarget.y = PosY;;
		}
		
		private function DragEnd(event:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE,DragMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP,DragEnd);
			DragTarget = null;
		}
		
		/**
		 * 创建组件代码
		 **/
		public function GenerateControlCode():String
		{
			//			var Code:String = "";
			//			//复合组件
			//			if(IsComplex)
			//			{
			//				Code = ClassFactory.GenerateClassByComplexUIControl(_Container,_Children,Package,ClassName);
			//			}
			//			else
			//			{
			//				Code = ClassFactory.GenerateClassByUIControl(_Children.pop(),Package,ClassName);
			//			}
			//			return Code;
			var ComClass:ComponentClass = new ComponentClass(_Container ?_Container:_Children[0] ,_ComponentProfile,_Children);
			return ComClass.Encode();
		}
		
		public function GenerateControlModel(Componenet:ComponentProfile):ByteArray
		{
			return ModelFactory.Instance.Encode(_Container ?_Container:_Children[0],_Children,Componenet);
		}
		
		public function DecodeModelByByte(Model:ByteArray):ComponentProfile
		{
			Model.position = 0;
			var Component:ComponentModel = ModelFactory.Instance.Decode(Model);
			_ComponentProfile = Component;
			Dispose();
			if(_ComponentProfile.Category == 1)
			{
				IsComplex = true;
				_Container = addChild(Component.Control) as Shell;
				_ContainerControl = _Container.Control as UIControl;
				for(var Idx:int=0; Idx<Component.Children.length; Idx++)
				{
					if(Component.Symbol[Idx] != null)
					{
						var CustomerComponent:ComponentModel = new ComponentModel();
						CustomerComponent.PackageName = StringUtil.trim(String(Component.Symbol[Idx]).substr(0,50));
						CustomerComponent.ClassName = StringUtil.trim(String(Component.Symbol[Idx]).substr(50));
						var a:ComponentModel = ModelFactory.Instance.FindModelByFullName(CustomerComponent.PackageName,CustomerComponent.ClassName);
						CustomerComponent.ModelByte = a.ModelByte;
						CustomerComponent.Category = a.Category;
						CustomerComponent.Control = Component.Children[Idx];
						AddComponent(CustomerComponent);
					}
					else
					{
						addChild(Component.Children[Idx]);
					}
				}
			}
			else
			{
				addChild(Component.Control);
			}
			
			return Component;
		}
		
		/**
		 * 模型数据解码
		 **/
		public function DecodeModel(ModelFile:File):void
		{
			var Reader:FileStream = new FileStream();
			if(ModelFile && ModelFile.exists)
			{
				Reader.open(ModelFile,FileMode.READ);
				var ModelData:ByteArray = new ByteArray();
				Reader.readBytes(ModelData,0,Reader.bytesAvailable);
				ModelData.position = 0;
				
				var Component:ComponentModel = ModelFactory.Instance.Decode(ModelData);
				_ComponentProfile = Component;
				Dispose();
				if(_ComponentProfile.Category == 1)
				{
					IsComplex = true;
					_Container = addChild(Component.Control) as Shell;
					_ContainerControl = _Container.Control as UIControl;
					_ContainerControl.EnableEditMode();
					for(var Idx:int=0; Idx<Component.Children.length; Idx++)
					{
						if(Component.Symbol[Idx] != null)
						{
							var CustomerComponent:ComponentModel = new ComponentModel();
							CustomerComponent.PackageName = String(Component.Symbol[Idx]).substr(0,50);
							CustomerComponent.ClassName = String(Component.Symbol[Idx]).substr(50);
							CustomerComponent.ModelByte = Component.Children[Idx].Encode();
							CustomerComponent.Control = Component.Children[Idx];
							this.AddComponent(CustomerComponent);
						}
						else
						{
							addChild(Component.Children[Idx]);
						}
					}
				}
				else
				{
					addChild(Component.Control);
				}
			}
		}
	}
}