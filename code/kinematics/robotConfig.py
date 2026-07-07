import numpy as np 
import roboticstoolbox as rtb 
############################################################################################
#robot configuration only edit this file                                                   #
#                                                                                          #
#rtb.DHRobot creates a dennavit hartenberg robot                                           #
#joint order (1, 2, ... , n)                                                               #
#attributes: (d(zDisplacement), a(xDisplacement), alpha(twistAngle), qlim(jointConstraint))#
#                                                                                          #
#rtb.RevoluteDh and rtb.PrismaticDH are the two joint declarations                         #
############################################################################################


#LIMB-HT25 defenition




#constant config 

A1 = 330 #mm
D2 = 87
D3 = 225
D5 = 272
################

#declaration

robot = rtb.DHRobot([
    rtb.RevoluteDH(d=0, a=A1, alpha=-np.pi/2),
    rtb.RevoluteDH(d=D2, a=0, alpha=-np.pi/2),
    rtb.RevoluteDH(d=D3, a=0, alpha=np.pi/2),
    rtb.RevoluteDH(d=0, a=0, alpha=-np.pi/2),
    rtb.RevoluteDH(d=D5, a=0, alpha=0)
])