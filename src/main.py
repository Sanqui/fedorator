from kivy.app import App
from kivy.uix.widget import Widget
from kivy.properties import NumericProperty, ObjectProperty, ReferenceListProperty
from kivy.vector import Vector
from kivy.clock import Clock

class FedoratorMenu(Widget):
    pass

class FedoratorApp(App):
    def build(self):
        menu = FedoratorMenu()
        return menu


if __name__ == '__main__':
    FedoratorApp().run()
