classdef volView < handle

    properties
        InitialCoord
        FineTuneC = [1 1/16]    % Regular/Fine-tune mode coefficients

        MaxV
        MinV
        LevV
        Win 

        % By how much to change the level as the user moves over the window
        % TODO: explore better ways of doing this
        LevelAdjustCoef = 0.5

        imStackOrig %The originally loaded image stack
        imStack %The image stack we plot

        View = 1  % Integer defining which axis we will slice and plot
        ViewLength % vector length 3 defining the number of planes along each axis
        currentSlice %The current slice to plot (vector length 3)

        % Sizes for fonts and so on
        SFntSz = 9
        LFntSz = 10
        WFntSz = 10
        VwFntSz = 10
        LVFntSz = 9
        WVFntSz = 9
        BtnSz = 10
        ChBxSz = 10
        Stxt_Pos
        Btn_Pos
        ChBx_Pos

        BtnStPnt %What is this?

        % Positions of figure elements
        Wtxt_Pos = [20 20 60 20]
        Wval_Pos = [75 20 60 20]
        posWval = [75 20 60 20]
        Ltxt_Pos = [140 20 45 20]
        Lval_Pos = [180 20 60 20]

        Vwtxt_Pos = [255 20 35 20]
        VAxBtn_Pos = [290 20 15 20]
        VSgBtn_Pos = [310 20 15 20]
        VCrBtn_Pos = [330 20 15 20]
        slider_Pos

        Rmin
        Rmax


        % Handles to stuff
        hFig % Figure window
        hAx  % Axes handle

        listeners = {}

        hButton_rangeReset
        hButton_View1
        hButton_View2
        hButton_View3
        hCheckBox
        hSlider
        hSliderText
        hText_Level
        hText_Window
        hValue_Level
        hValue_Window
        hText_View

    end

    properties (Hidden)
        cachedDemoDataLocation
    end


    methods
        function obj = volView(Img,disprange)
            % volView displays 3D grayscale or RGB images from three perpendicular
            % views (e.g. axial, sagittal, and coronal) in slice by slice fashion with
            % mouse based slice browsing and window and level adjustment control.
            %
            % For a demo run:
            % >> volView;
            %
            % 
            % Usage:
            % volView(Image)
            % volView(Image, [])
            % volView(Image, [LOW HIGH])
            %   
            %    Image:      3D image MxNxKxC (K slices of MxN images) C is either 1
            %                (for grayscale images) or 3 (for RGB images)
            %    [LOW HIGH]: display range that controls the display intensity range of
            %                a grayscale image (default: the widest available range)
            %
            % Use the scroll bar or mouse scroll wheel to switch between slices. To
            % adjust window and level values keep the mouse right button pressed and
            % drag the mouse up and down (for level adjustment) or right and left (for
            % window adjustment). Window and level adjustment control works only for
            % grayscale images.
            %
            % Use the on-screen buttons '1', '2', and '3' buttons to switch between views.
            % 
            % "Reset W/L" button resets the image level range.
            %
            % While "Fine Tune" check box is checked the window/level adjustment gets
            % 16 times less sensitive to mouse movement, to make it easier to control
            % display intensity rang.
            %
            % Note: The sensitivity of mouse based window and level adjustment is set
            % based on the user defined display intensity range; the wider the range
            % the more sensitivity to mouse drag.
            % 
            % 
            %   Example
            %   --------
            %   Display an image (MRI example)
            %   load mri 
            %   V=volView(squeeze(D));
            %
            %    % Display the image, adjust the display range
            %    V=volView(Image,[5 30]);
            %
            %
            % - Maysam Shahedi (mshahedi@gmail.com)
            % - Released: 1.0.0   Date: 2013/04/15 MS
            % - Revision: 1.1.0   Date: 2013/04/19 MS
            % - Revision: 2.0.0   Date: 2014/08/05 MS
            % - Revision: 2.5.0   Date: 2016/09/22 MS
            % - Revision: 2.5.1   Date: 2018/10/29 MS
            %
            % ** Massive refactor & tidy. Convert to a class (Rob Campbell, Sainsbury Wellcome Centre)
            % - Revision: 3.0.0   Date: 2019/10/09 RC


            % Load the demo image if needed
            if nargin==0 || (isstr(Img) && strcmp(Img,'demo'))
                obj.getAndCacheDemoImage
                % Load tiff stack
                fprintf('Loading demo stack from disk')
                warning off
                imageInfo=imfinfo(obj.cachedDemoDataLocation);
                warning on
                numFrames=length(imageInfo);
                imSize=[imageInfo(1).Height,imageInfo(1).Width,numFrames];
                Img=imread(obj.cachedDemoDataLocation,1);
                Img=repmat(Img,[1,1,numFrames]);
                for frame=2:numFrames
                    if mod(frame,10)==0, fprintf('.'), end
                    Img(:,:,frame)=imread(obj.cachedDemoDataLocation,frame);
                end
                fprintf('\n')
            end
            if nargin<2
                disprange=[];
            end

            obj.buildFigureWindow
            obj.displayNewImageStack(Img,disprange)

        end %volView


        function delete(obj)
            cellfun(@delete,obj.listeners)
            obj.hFig.delete
        end


        function windowCloseFcn(obj,~,~)
            % This runs when the user closes the figure window
            obj.delete % simply call the destructor
        end % Close windowCloseFcn



        function displayNewImageStack(obj,Img,disprange)
            % Sets up a bunch of default values for variables when a new imgage is to be displayed
            % Then displays the image with showImage
            if size(Img,3) == 1
                fprintf('\n\n ** Image is a single plane not a stack. Will not proceed\n\n');
                return
            end

            obj.MinV = min(Img(:));
            obj.MaxV = max(Img(:));
            obj.LevV = (obj.MaxV + obj.MinV) / 2;
            obj.Win =  obj.MaxV - obj.MinV;

            % TODO: we can get rid of obj.LevV and obj.Win as this information is present in the string value
            obj.hValue_Level.String = obj.LevV;
            obj.hValue_Window.String = obj.Win;

            obj.imStackOrig = Img;
            obj.imStack = Img;
            obj.View = 1; % Default view is the first one
            obj.ViewLength = fliplr(size(Img));
            obj.currentSlice = round(obj.ViewLength/2); % default slice in each axis is the middle slice

            obj.updateSliderScale

            if (nargin<3) || isempty(disprange)
                [obj.Rmin obj.Rmax] = windowLevel2Range(obj.Win, obj.LevV);
                obj.WinLevChanged
            else
                disp('Setting window level based on user-defined range')
                obj.LevV = mean(disprange);
                obj.Win = diff(disprange);
                [obj.Rmin obj.Rmax] = windowLevel2Range(obj.Win, obj.LevV);
                obj.updateWindowAndLevelBoxes
            end
            obj.showImage
        end %displayNewImageStack


        function showImage(obj)
            % Displays the current selected plane.
            % This method is called by displayNewImageStack and switchView
            imshow(squeeze(obj.imStack(:,:,obj.currentSlice(obj.View),:)), [obj.Rmin obj.Rmax],'parent',obj.hAx)
            set(get(obj.hAx,'Children'),'ButtonDownFcn', @obj.mouseClick);
        end


        function updateSliderScale(obj)
            % Update the max value of the slider
            maxVal = obj.ViewLength(obj.View);
            obj.hSlider.Max = maxVal;
            obj.hSlider.Value = obj.currentSlice(obj.View);
            obj.hSlider.SliderStep = [1/(maxVal-1), 10/(maxVal-1)];
            obj.updateSliderText
        end


        function updateSliderText(obj)
            maxVal = obj.ViewLength(obj.View);
            set(obj.hSliderText, 'String', sprintf('Slice# %d / %d',obj.currentSlice(obj.View), maxVal));
        end

    end %Main methods


    % Callbacks follow
    methods

        function figureResized(obj,~,~)
            % TODO: should all this not be needed if we use relative positions?
            FigPos = obj.hFig.Position;
            obj.slider_Pos = [50 45 FigPos(3)-100+1 20];
            obj.Stxt_Pos = [50 65 FigPos(3)-100+1 15];

            obj.BtnStPnt = FigPos(3)-210+1;
            if obj.BtnStPnt < 360
                 obj.BtnStPnt = 360;
            end
            obj.Btn_Pos = [obj.BtnStPnt 20 80 20];
            obj.ChBx_Pos = [obj.BtnStPnt+90 20 100 20];
            obj.hSlider.Position=obj.slider_Pos;

            set(obj.hSliderText,'Position', obj.Stxt_Pos);
            set(obj.hText_Level,'Position', obj.Ltxt_Pos);
            set(obj.hText_Window,'Position', obj.Wtxt_Pos);
            set(obj.hValue_Level,'Position', obj.Lval_Pos);
            set(obj.hValue_Window,'Position', obj.Wval_Pos);
            set(obj.hButton_rangeReset,'Position', obj.Btn_Pos);
            set(obj.hCheckBox,'Position', obj.ChBx_Pos);
            set(obj.hText_View,'Position', obj.Vwtxt_Pos);
            set(obj.hButton_View1,'Position', obj.VAxBtn_Pos);
            set(obj.hButton_View2,'Position', obj.VSgBtn_Pos);
            set(obj.hButton_View3,'Position', obj.VCrBtn_Pos);
        end


        function SliceSlider (obj,src,~)
            obj.currentSlice(obj.View) = round(get(src,'Value'));
            set(get(obj.hAx,'children'),'cdata',squeeze(obj.imStack(:,:,obj.currentSlice(obj.View),:)))
            caxis([obj.Rmin obj.Rmax])
            obj.updateSliderText
        end


        function mouseScroll (obj,~,eventdata)
            UPDN = eventdata.VerticalScrollCount;
            obj.currentSlice(obj.View) = obj.currentSlice(obj.View) - UPDN;

            if obj.currentSlice(obj.View) < 1
                obj.currentSlice(obj.View) = 1;
            elseif obj.currentSlice(obj.View) > obj.ViewLength(obj.View)
                obj.currentSlice(obj.View) = obj.ViewLength(obj.View);
            end

            %% TODO: the following is then repeated in a horrible way when switching axes
            obj.hSlider.Value=obj.currentSlice(obj.View);
            obj.updateSliderText
            set(get(obj.hAx,'children'),'CData',squeeze(obj.imStack(:,:,obj.currentSlice(obj.View),:)))
        end


        function mouseRelease (obj,~,~)
            set(obj.hFig, 'WindowButtonMotionFcn', '')
        end


        function mouseClick (obj,~,~)
            MouseStat = get(gcbf, 'SelectionType');
            if (MouseStat(1) == 'a')        %   RIGHT CLICK
                obj.InitialCoord = get(0,'PointerLocation');
                set(obj.hFig, 'WindowButtonMotionFcn', @obj.WinLevAdj);
            end
        end


        function updateWindowAndLevelBoxes(obj,~,~)
            set(obj.hValue_Level, 'String', obj.LevV);
            set(obj.hValue_Window, 'String', obj.Win);
        end

        function WinLevAdj(obj,~,~)
            % Adjust the level of the image as the user right-click drags
            PosDiff = get(0,'PointerLocation') - obj.InitialCoord;
            obj.Win = obj.Win + PosDiff(1) * obj.LevelAdjustCoef * obj.FineTuneC(obj.hCheckBox.Value+1);
            obj.LevV = obj.LevV - PosDiff(2) * obj.LevelAdjustCoef * obj.FineTuneC(obj.hCheckBox.Value+1);
            if obj.Win<1
                obj.Win = 1;
            end
            [obj.Rmin, obj.Rmax] = windowLevel2Range(obj.Win,obj.LevV);

            caxis([obj.Rmin, obj.Rmax])
            obj.updateWindowAndLevelBoxes
            obj.InitialCoord = get(0,'PointerLocation');
        end


        function WinLevChanged(obj,~,~)
            obj.LevV = str2double(get(obj.hValue_Level, 'string'));
            obj.Win = str2double(get(obj.hValue_Window, 'string'));
            if obj.Win<1
                obj.Win = 1;
            end

            [obj.Rmin, obj.Rmax] = windowLevel2Range(obj.Win,obj.LevV);
            caxis([obj.Rmin, obj.Rmax])
        end


        function rangeReset(obj,~,~)
            % Reset the lookup table so it spans the full range of the image. 
            % i.e. This is *not* what one would traditionally think of as "auto-contrast"
            obj.Win = range(obj.imStack(:));
            if obj.Win<1
                obj.Win = 1;
            end
            obj.LevV = double(min(obj.imStack(:)) + (obj.Win/2));
            [obj.Rmin, obj.Rmax] = windowLevel2Range(obj.Win,obj.LevV);
            caxis([obj.Rmin, obj.Rmax])
            obj.updateWindowAndLevelBoxes
        end


        function switchView(obj,src,~)
            % Switch the displayed image to slice along a different axis
            if nargin==1
                src.String='1';
            end
            obj.View = str2num(src.String);

            if obj.View == 1
                obj.imStack = obj.imStackOrig;
            elseif obj.View == 2
                obj.imStack = flip(permute(obj.imStackOrig, [3 1 2 4]),1);
            elseif obj.View == 3
                obj.imStack = flip(permute(obj.imStackOrig, [3 2 1 4]),1);
            end
            obj.updateSliderScale
            obj.showImage
        end


    end %callback methods

end %classdef