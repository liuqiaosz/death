package editor.ui
{
	import flash.events.MouseEvent;
	
	import mx.events.CloseEvent;
	
	import spark.components.TitleWindow;
	
	import editor.uitility.ui.event.UIEvent;

	public class AdvanceTitleWindow extends TitleWindow
	{
		public function AdvanceTitleWindow()
		{
			addEventListener(CloseEvent.CLOSE,OnCloseWindow);
		}
		
		private function OnCloseWindow(event:CloseEvent):void
		{
			removeEventListener(CloseEvent.CLOSE,OnCloseWindow);
			CloseWindow();
		}
		
		public function CloseWindow():void
		{
			var Notify:UIEvent = new UIEvent(UIEvent.WINDOW_CLOSE);
			dispatchEvent(Notify);
		}
		
		protected function Close(event:MouseEvent):void
		{
			CloseWindow();
		}
	}
}