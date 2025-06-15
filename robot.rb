require 'java'
require 'controllable_thread'
require 'robot/keycodes'
require 'robot/jrobot-pause'


java_import java.awt.Toolkit
java_import java.awt.Color
java_import java.awt.event.InputEvent
java_import java.util.concurrent.locks.ReentrantLock
java_import Java::org.foa.robot.RobotLock
java_import Java::org.foa.robot.ARobot

RobotPauser.instance
