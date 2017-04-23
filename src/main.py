from kivy.app import App
from kivy.uix.widget import Widget
from kivy.properties import NumericProperty, StringProperty, ObjectProperty, ReferenceListProperty
from kivy.vector import Vector
from kivy.clock import Clock

import usbdisks

class FedoratorMenu(Widget):
    disk_text = StringProperty()
    
    def update_disks(self, dt):
        disks = usbdisks.get_usb_disks()
        self.disk_text = ", ".join(disk.dev_name for disk in disks)

class FedoratorApp(App):
    def build(self):
        menu = FedoratorMenu()
        Clock.schedule_interval(menu.update_disks, 1.0)
        return menu


if __name__ == '__main__':
    FedoratorApp().run()
