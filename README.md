# volView
This is a simple image stack visualizer for MATLAB. 
It is based upon [imshow3Dfull](https://www.mathworks.com/matlabcentral/fileexchange/47463-imshow3dfull). 
Compared to that project this one initially is planned to have the following significant changes:
* Renamed from imshow3Dfull to volView and converted to a class to ease further development
* Variable names renamed for clarity
* Code cleaned up (e.g. removal of unnecessary type conversions) 
* Code refactored (mainly to remove redundancy)



## Usage
To try the viewer with a demo dataset run:
```
>> volViewer
```

## Planned changes
* Improved slider behavior with listener and `PostSet`
* Add a true auto-contrast button 
* Allow for non-square pixels
* Correct image scaling problems with other views
* Rename views from Coronal, Sagittal and Axial since the validity of these labels depends on the orientation of the dataset and there is no reason to think datasets will even be anatomical. 
* Explore whether the `figureResized` callback can be removed by using relative positioning 

## Longer term changes
* Allow overlay of annotations such as borders or annotated features
* Handle multiple channels