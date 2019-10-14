classdef volView < handle

    properties

        FineTuneC = [1 1/16]    % Regular/Fine-tune mode coefficients

        MaxV
        MinV
        LevV
        Win

        % By how much to change the level as the user moves over the window
        % TODO: explore better ways of doing this? Works well enough so far, though
        LevelAdjustCoef = 0.5

        imStackOrig % The originally loaded image stack
        imStack     % The image stack we plot
        lineData    % Lines that we will overlay go here

        View = 1     % Integer defining which axis we will slice and plot
        imStackSize   % Vector length 3 defining the number of planes along each axis
        currentSlice % The current slice to plot (vector length 3)

        % Max and min values of look-up table (TODO: this can be done better for sure)
        Rmin
        Rmax

        % Handles to stuff
        hFig   % Figure window
        hAx    % Axes handle
        hIm    % Handle to plotted image
        hLines % Plotted lines all go here
        hSliceLines % Plot handles for lines that indicate current plane of other views

        % Handles to GUI elements
        hButton_rangeReset
        hButton_View % The three buttons for the views sit in this vector
        hCheckBox
        hSlider
        hText_Level
        hText_Window
        hValue_Level
        hValue_Window
        hText_View
    end

    properties (Hidden)
        cachedDemoDataLocation %Where the demo mouse brain was saved after it was downloaded

        InitialCoord % Used for changing contrast with right-click and drag

        % Positions of figure elements
        Wtxt_Pos = [20 20 60 20]
        Wval_Pos = [75 20 60 20]
        posWval  = [75 20 60 20]
        Ltxt_Pos = [140 20 45 20]
        Lval_Pos = [180 20 60 20]

        Vwtxt_Pos  = [255 20 35 20]
        VAxBtn_Pos = [290 20 15 20]
        VSgBtn_Pos = [310 20 15 20]
        VCrBtn_Pos = [330 20 15 20]
        slider_Pos
        Stxt_Pos
        Btn_Pos
        ChBx_Pos

        BtnStPnt % Button start point (used for relative positioning that may be a hack)

        listeners = {}
    end


    methods
        function obj = volView(Img,disprange,lineData)
            % volView is a slicing viewer for 3D grayscale or RGB images
            %
            % Purpose 
            % Allows slicing views (e.g. axial, sagittal, and coronal) with
            % mouse-based slice browsing and window and level adjustment control.
            %
            % For a demo displaying a mouse brain image run:
            % >> volView;
            %
            % 
            % Usage:
            % volView(Image)
            % volView(Image, [])
            % volView(Image, [LOW HIGH])
            %
            % Inputs
            %  Image:   EITHER a 3D image MxNxKxC (K slices of MxN images) C is either 1
            %              (for grayscale images) or 3 (for RGB images) 
            %           OR a path to a tiff stack or a .mat file containing an image stack
            %  [LOW HIGH]: display range that controls the display intensity range of
            %              a grayscale image (default: the widest available range)
            %  lineData: Optional cell array of cell arrays containing line data to 
            %            overlay onto a plot. See generateBorders in the examples folder.
            %            Not all views need to be populated with line data
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
            % * Example session
            % >> load mri % Loads MRI image as matrix "D"
            % >> V=volView; % Displays demo mouse brain
            % Loading demo stack from disk...................
            % >> V.displayNewImageStack(squeeze(D)) % Now display the MRI image
            % >> V.displayNewImageStack(squeeze(D),[5,30]) % Again but with different look-up table
            % >> delete(V) % Close the GUI at the command line
            %
            %
            % Rob Campbell - October 2019, SWC
            % Original version by Maysam Shahedi (mshahedi@gmail.com)

            % Load the demo image if needed
            if nargin==0 || (ischar(Img) && strcmp(Img,'demo'))
                obj.getAndCacheDemoImage
                fprintf('Loading demo stack from disk')
                Img = loadTiffStack(obj.cachedDemoDataLocation);
            end

            if ischar(Img) && exist(Img)
                %Load from disk
                fname=Img;
                [~,~,ext]=fileparts(fname);
                if strcmpi(ext,'.tif') || strcmpi(ext,'.tiff')
                    fprintf('Loading %s\n', fname);
                    Img = loadTiffStack(Img);
                elseif strcmpi(ext,'.mat')
                    fprintf('Loading %s\n', fname);
                    D=load(fname);
                    TT = load(fname);
                    ff = fields(TT);
                    if length(ff)>1
                        fprintf('.mat file %s comtains multiple variables. It should contain only one.\n', fname );
                        obj.delete
                        return
                    end
                    Img = TT.(ff{1});
                else
                    fprintf('Unknown file format for file %s\n', fname)
                    obj.delete
                    return
                end
            end

            if nargin<2
                disprange=[];
            end

            if nargin<3
                lineData=[];
            end


            obj.buildFigureWindow
            obj.displayNewImageStack(Img,disprange,lineData)

        end %volView


        function delete(obj)
            cellfun(@delete,obj.listeners)
            obj.hFig.delete
        end


        function windowCloseFcn(obj,~,~)
            % This runs when the user closes the figure window
            obj.delete % simply call the destructor
        end % Close windowCloseFcn



        function displayNewImageStack(obj,Img,disprange,lineData)
            % Sets up a bunch of default values for variables when a new imgage is to be displayed
            % Then displays the image with showImage
            if isempty(Img)
                fprintf('Image stack is empty!\n')
                return
            end

            if size(Img,3) == 1
                fprintf('\n\n ** Image is a single plane not a stack. Will not proceed\n\n');
                return
            end


            if nargin<3 || isempty(lineData)
                obj.lineData=[];
            else
                obj.lineData=lineData;
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

            obj.updateViewButtons

            obj.imStackSize = fliplr(size(Img));
            obj.currentSlice = round(obj.imStackSize/2); % default slice in each axis is the middle slice

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


        function addLinesToPlot(obj)
            % Add overlay lines if these are available

            % Bail out if no suitable line data exist
            if isempty(obj.lineData)
                return
            end

            if length(obj.lineData)<obj.View
                return
            end

            if isempty(obj.lineData{obj.View})
                return
            end

            % Delete any existing lines
            for ii=1:length(obj.hLines)
                try 
                    delete(obj.hLines(ii))
                catch
                end
            end


            tSlice = obj.currentSlice(obj.View);
            if length(obj.lineData{obj.View})<tSlice
                return
            end
            hold on
            if ~isempty(obj.lineData{obj.View}{tSlice})
                t=obj.lineData{obj.View}{tSlice};
                for ii=1:length(t)
                    obj.hLines(ii) = plot(t{ii}(:,2),t{ii}(:,1),'-r');
                end
            end
            hold off
        end


        function showImage(obj)
            % Displays the current selected plane.
            % This method is called by displayNewImageStack and switchView
            tSlice=obj.currentSlice(obj.View);
            obj.hIm = imshow(squeeze(obj.imStack(:,:,tSlice,:)), [obj.Rmin obj.Rmax],'parent',obj.hAx);
            set(obj.hIm,'ButtonDownFcn', @obj.mouseClick);

            obj.addLinesToPlot
            hold on
            % Add lines indicating the planes of the other views
            if obj.View == 1
                obj.hSliceLines(1) = plot([obj.currentSlice(2),obj.currentSlice(2)],ylim,':g');
                obj.hSliceLines(2) = plot(xlim,[obj.currentSlice(3),obj.currentSlice(3)],':','color',[0.2,0.2,1]);
            elseif obj.View == 2
                obj.hSliceLines(1) = plot([obj.currentSlice(3),obj.currentSlice(3)],ylim,':','color',[0.2,0.2,1]);;
                obj.hSliceLines(2) = plot(xlim,[obj.currentSlice(1),obj.currentSlice(1)],':r');
            elseif obj.View == 3
                obj.hSliceLines(1) = plot(xlim,[obj.currentSlice(1),obj.currentSlice(1)],':r');
                obj.hSliceLines(2) = plot([obj.currentSlice(2),obj.currentSlice(2)],ylim,':g');
            end
            set([obj.hSliceLines],'LineWidth',2)
            hold off

        end


        function updateSliderScale(obj)
            % Update the max value of the slider
            maxVal = obj.imStackSize(obj.View);
            obj.hSlider.Max = maxVal;
            obj.hSlider.Value = obj.currentSlice(obj.View);
            obj.hSlider.SliderStep = [1/(maxVal-1), 10/(maxVal-1)];
            obj.updateSliderText
        end


        function updateSliderText(obj)
            maxVal = obj.imStackSize(obj.View);
            obj.hFig.Name = sprintf('Slice# %d/%d',obj.currentSlice(obj.View), maxVal);
        end


        function updateViewButtons(obj)
            % Highlight button of current view
            set([obj.hButton_View],'FontWeight','normal')
            set(obj.hButton_View(obj.View),'FontWeight','bold')
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

            set(obj.hText_Level,'Position', obj.Ltxt_Pos);
            set(obj.hText_Window,'Position', obj.Wtxt_Pos);
            set(obj.hValue_Level,'Position', obj.Lval_Pos);
            set(obj.hValue_Window,'Position', obj.Wval_Pos);
            set(obj.hButton_rangeReset,'Position', obj.Btn_Pos);
            set(obj.hCheckBox,'Position', obj.ChBx_Pos);
            set(obj.hText_View,'Position', obj.Vwtxt_Pos);
            set(obj.hButton_View(1),'Position', obj.VAxBtn_Pos);
            set(obj.hButton_View(2),'Position', obj.VSgBtn_Pos);
            set(obj.hButton_View(3),'Position', obj.VCrBtn_Pos);
        end


        function SliceSlider (obj,~,~)
            % This callback is run by a listener on obj.hSlider.Value
            obj.currentSlice(obj.View) = round(obj.hSlider.Value);
            obj.hIm.CData = squeeze(obj.imStack(:,:,obj.currentSlice(obj.View),:));
            obj.addLinesToPlot
            obj.updateSliderText
        end


        function mouseScroll (obj,~,eventdata)
            % Run when user scrolls mouse wheel over image window. 
            % Updates slider and image
            newSliceToPlot = obj.currentSlice(obj.View) - eventdata.VerticalScrollCount;
            if newSliceToPlot < 1
                newSliceToPlot = 1;
            elseif newSliceToPlot > obj.imStackSize(obj.View)
                newSliceToPlot = obj.imStackSize(obj.View);
            end
            obj.hSlider.Value=newSliceToPlot;
            obj.updateSliderText
        end


        function mouseRelease (obj,~,~)
            set(obj.hFig, 'WindowButtonMotionFcn', '')
        end


        function mouseClick (obj,~,~)
            MouseStat = get(gcbf, 'SelectionType');
            if (MouseStat(1) == 'a') % This is a right click
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

            % Permute axes
            if obj.View == 1
                obj.imStack = obj.imStackOrig;
            elseif obj.View == 2
                obj.imStack = permute(obj.imStackOrig, [3 1 2 4]);
            elseif obj.View == 3
                obj.imStack = permute(obj.imStackOrig, [3 2 1 4]);
            end

            obj.updateViewButtons
            obj.updateSliderScale
            obj.showImage
        end


    end %callback methods

end %classdef