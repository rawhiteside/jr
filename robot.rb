require 'java'
require 'controllable_thread'
require 'robot/keycodes'
require 'robot/jrobot-pause'


import java.awt.Toolkit
import java.awt.Color
import java.awt.event.InputEvent
import java.util.concurrent.locks.ReentrantLock
import Java::org.foa.robot.RobotLock
import Java::org.foa.robot.ARobot

RobotPauser.new
