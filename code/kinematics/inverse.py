import numpy as np 
import roboticstoolbox as rtb 
from spatialmath import SE3

from robotConfig import robot as ROBOT 




testPosition = SE3(0, 0, 0)
state = ROBOT.ikine_LM(testPosition)
print(state)