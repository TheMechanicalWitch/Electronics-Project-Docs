# To do

- Implement a check for when the arm is locked due to a singularity point, which then triggers a reset of the virtual arm position (`current_configuration` in `arm_visualizer.jl`) or nudges it out of the lock.
- Implement a map which scales the target points (coordinate system of the camera output) such that the lengths between them matches the length of the virtual (and physical) arm. This will allow people with arm lengths which do not match the robot to control it all the same.
- Modify the virtual geometry and kinematics equations to match the real robot arm. (There are two extra offsets in the real robot arm betweent the shoulder (2nd joint) and the elbow, and between the elbow and lower arm/wrist rotation. Also update the joint lengths to match the ones in the SolidWorks file.
  - Write a general forward kinematics function for any list of sucessive joints and offsets.
- Implement support for two cameras looking at the person at different angles and agreeing on the interest point positions.
  - Normalize the angle of the shoulder to be relative to the other shoulder (such that the arm doesn't rotate when you rotate your body). This will allow the arm to be controlled with the camera lookin at a side view angle).
- Work on identifying the angle of the wrist
- Work on identifying hand angles or hand states
