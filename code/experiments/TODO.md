# To do

- Implement a check for when the arm is locked due to a singularity point, which then triggers a reset of the virtual arm position (`current_configuration` in `arm_visualizer.jl`) or nudges it out of the lock. This can perhaps be done by modifying `joint_constraint_fitness` such that it penalizes angles *close* to their limits (not because there is something inherently bad with being close to or at the joint limits -- but because the singularity problems often occur at positions where the arm joints are at their limits, since, rather interestingly, humans like to set the joint limits at "logical" angles, such as 0 or 90 degrees).
- Implement a map which scales the target points (coordinate system of the camera output) such that the lengths between them matches the length of the virtual (and physical) arm. This will allow people with arm lengths which do not match the robot to control it all the same.
- Modify the virtual geometry and kinematics equations to match the real robot arm. (There are two extra offsets in the real robot arm betweent the shoulder (2nd joint) and the elbow, and between the elbow and lower arm/wrist rotation. Also update the joint lengths to match the ones in the SolidWorks file.
  - Write a general forward kinematics function for any list of sucessive joints and offsets.
- Implement support for two cameras looking at the person at different angles and agreeing on the interest point positions.
  - Normalize the angle of the shoulder to be relative to the other shoulder (such that the arm doesn't rotate when you rotate your body). This will allow the arm to be controlled with the camera lookin at a side view angle).
- Try to make the `Optim.minimizer`/`optimize` function faster, or rewrite the function from scratch in order to obtain more control over how it works (which would not be too difficult, and also fun).
- Work on identifying the angle of the wrist
- Work on identifying hand angles or hand states
