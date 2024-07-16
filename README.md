# Structured-light-based-Living-skin-Detection

This is code repository for the paper "Living-Skin Detection based on Spatio-Temporal Analysis of Structured Light Pattern". 

Motivated by the laser reflection properties of living-skin, we proposed a new measurement principle, concept and method for living-skin detection, which uses structured laser spots projected on human skin to detect living-skin pixels. We proposed a novel hybrid feature set (STEOG+STWTV) to extract the properties of laser spot sharpness and brightness fluctuations, which in turn distinguishes between skin and non-skin regions. This method was validated in both the dark chamber and hospital enviroment (NICU), achieving a precision of 85.32%, recall of 83.87%, and F1-score of 83.03% averaged over these two scenes. 

In this repo, our proposed method is implemented in run_living_skin_detection.m of Matlab code, and the clips file provides the demo video, including Lab and NICU settings, for testing. 

Please cite below paper if the code was used in your research or development.

    @ARTICLE{Wang2024,
      author={Wang, Zhiyu and Liao, ChuChu and Pan, Liping and Lu, Hongzhou and Shan, Caifeng and Wang, Wenjin},
      journal={IEEE Journal of Biomedical and Health Informatics}, 
      title={Living-Skin Detection based on Spatio-Temporal Analysis of Structured Light Pattern (under revision)}, 
      year={2024},
    }
