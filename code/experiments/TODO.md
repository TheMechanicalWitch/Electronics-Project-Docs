# To do

- Implement a check for when the arm is locked due to a singularity point, which then triggers a reset of the virtual arm position (`current_configuration` in `arm_visualizer.jl`) or nudges it out of the lock.
- Implement a map which scales the target points (coordinate system of the camera output) such that the lengths between them matches the length of the virtual (and physical) arm. This will allow people with arm lengths which do not match the robot to control it all the same.
- Modify the virtual geometry and kinematics equations to match the real robot arm. (There are two extra offsets in the real robot arm betweent the shoulder (2nd joint) and the elbow, and between the elbow and lower arm/wrist rotation. Also update the joint lengths to match the ones in the SolidWorks file.
  - Write a general forward kinematics function for any list of sucessive joints and offsets.
