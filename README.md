# volView
This is a simple image stack visualizer for MATLAB. 
It is based upon [imshow3Dfull](https://www.mathworks.com/matlabcentral/fileexchange/47463-imshow3dfull). 
Compared to that project this has the following significant changes:
* `imshow3Dfull` is now a class called `volView` to ease further development
* Code massively refactored, mainly to remove redundancy, and also cleaned up to get rid of things like unnecessary type conversions.
* Most variables renamed for clarity
* Renamed views from Coronal, Sagittal and Axial since the validity of these labels depends on the orientation of the dataset and there is no reason to expect datasets to be anatomical. 


### Usage
To try the viewer with a demo dataset run:
```
>> volViewer
```

### Planned changes
* Improved slider behavior with listener and `PostSet` so image updates whilst slider is being moved.
* Add a true auto-contrast button.
* Allow for non-square pixels and correct image scaling problems with other views (they become non-square even when they should be).
* Explore whether the `figureResized` callback can be removed by using relative positioning 

### Longer term changes
* Allow overlay of annotations such as borders or annotated features
* Handle multiple channels