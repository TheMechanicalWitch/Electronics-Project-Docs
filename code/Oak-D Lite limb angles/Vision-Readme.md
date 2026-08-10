<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a id="readme-top"></a>


<h1 align="center">Human limb position and angle identification</h1>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project
<br />
<div align="center">
  <p>
    <img src="ArmHandVision.gif" alt="Logo">
  </p>
</div>

This program is used together with the Oak-D Lite camera to measure and visualize the angle between the lower and upper arms as well as the posional data of the hand and fingers. The purpose is to later use this data to help control the LIMB robotic arm or simulation software in conjunction to the LIMB project.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



### Built With
[![DepthAI][DepthAI]][DepthAI-url]  
[![MediaPipe][MediaPipe]][MediaPipe-url]  
[![OpenCV][OpenCV]][OpenCV-url]  
[![Python][Python]][Python-url]  

[DepthAI]: https://img.shields.io/badge/DepthAI-000000?logo=lens&logoColor=white
[DepthAI-url]: https://docs.luxonis.com/software-v3/depthai/

[MediaPipe]: https://img.shields.io/badge/MediaPipe-0097A7?logo=google&logoColor=white
[MediaPipe-url]: https://ai.google.dev/edge/mediapipe

[OpenCV]: https://img.shields.io/badge/OpenCV-5C3EE8?logo=opencv&logoColor=white
[OpenCV-url]: https://opencv.org/

[Python]: https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white
[Python-url]: https://www.python.org/

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

This is an example of how you may give instructions on setting up your project locally.
To get a local copy up and running follow these simple example steps.

### Prerequisites

This is an example of how to list things you need to use the software and how to install them.
* python 3.12.3
  ```sh
  sudo apt install python3.12.3
  ```
* Depth-AI v3
  ```sh
  git clone https://github.com/luxonis/depthai-core.git && cd depthai-core  
  python3 -m venv venv  
  source venv/bin/activate  
  # Installs library and requirements
  python3 examples/python/install_requirements.py
  ```
  * or via pip
  ```
    pip install depthai --force-reinstall
  ```
### Installation
1. Install prerequisites
2. Curl the file
   ```sh
    curl -L -o camera_data_UDP_server.py "https://raw.githubusercontent.com/TheMechanicalWitch/Electronics-Project-Docs/main/code/Oak-D%20Lite%20limb%20angles/camera_data_UDP_server.py"
   ```
3. Run the python file whilst the "Oak-D lite" cammera is connected via USB3 or USB-C.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage
When the software is running it will show the video output of the camera as well as a dedicated depthmap. The software will track the normalised positional values of the shoulder to elbow, elbow to wrist, and 21 different landmarks positions in the hand.  
From these 21 different landmarks, the vector for the different finger (finger vectors) will be tracked to determine whether that specific finger is curled or uncurled. The normal vector for the hand is also calculated to determine whether the hand is facing towards or away from the camera. The data is sent as JSON packages and listed as dictionary items with their associated values that are used and translated by the client into data used by the simulation software. This can be later expanded to be used as a real time controller for the LIMB.  


If the software were to be unable to run or crash due to overheating of the hardware (known problem), then the recommended action is to let the software cooldown before running the command
```
  kill -SIGKILL $(pgrep -f camera_data_UDP_server.py)
```
And trying to run it again.  
Pressing the Q button will close the software, this is recommended over using forced quitting (ctrl z, or ctrl c) since it might cause the software to bug needing to follow the previous step.
<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ROADMAP -->
## Roadmap

- [X] Track the arms positional data from the shoulder to elbow.
- [X] Track the hand and finger positional data.
- [X] Track the wrist rotational data.
- [ ] Track the positional data facing the camera from the side.
- [ ] Send and translate positional data to the LIMB for movement

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTRIBUTING -->
## Contributing

Contributions are what makes the LIMB project possible.

If you have a suggestion or improvements that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- CONTACT -->
## Contact

Whilliam Borglund Head of Vision - Wbd220001@student.mdu.se  
Adrian Swande Head of simulation - Ade22XXXX@student.mdu.se

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* Adam Nyberg(For constructing the fan-casing for the camera hardware as well as early testing and contribution)

<p align="right">(<a href="#readme-top">back to top</a>)</p>
