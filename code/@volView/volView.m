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

        View = 'A'
        currentSlice %The current slice to plot

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



        sno %Number of slices along current axis
        %TODO: we can likely get rid of these somehow
        sno_a
        sno_s
        sno_c
        S_a
        S_s
        S_c

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
            %volView displays 3D grayscale or RGB images from three perpendicular
            %views (i.e. axial, sagittal, and coronal) in slice by slice fashion with
            %mouse based slice browsing and window and level adjustment control.
            %
            % For a demo run:
            % >> v=volView('demo')
            %
            % 
            % Usage:
            % volView (Image)
            % volView (Image, [])
            % volView (Image, [LOW HIGH])
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
            % Use 'A', 'S', and 'C' buttons to switch between axial, sagittal and
            % coronal views, respectivelly.
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
            %       % Display an image (MRI example)
            %       load mri 
            %       Image = squeeze(D); 
            %       V=volView(Image);
            %
            %       % Display the image, adjust the display range
            %       V=volView(Image,[20 100]);
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


            % Set up the figure window
            obj.hFig = figure;
            obj.hFig.CloseRequestFcn = @obj.windowCloseFcn;
            obj.hFig.ToolBar='none';
            obj.hFig.MenuBar='none';

            obj.hAx = axes('position',[0,0.2,1,0.8]);

            FigPos = obj.hFig.Position;
            obj.slider_Pos = [50 50 FigPos(3)-100+1 20];
            obj.Stxt_Pos = [50 70 FigPos(3)-100+1 15];

            obj.BtnStPnt = FigPos(3)-210+1;
            if obj.BtnStPnt < 360
                obj.BtnStPnt = 360;
            end

            obj.Btn_Pos = [obj.BtnStPnt 20 80 20];
            obj.ChBx_Pos = [obj.BtnStPnt+90 20 100 20];


            obj.hSlider = uicontrol(gcf,'Style', 'slider','Min',0,'Max',1,'Position', obj.slider_Pos,'Callback', @obj.SliceSlider);
            obj.hSliderText = uicontrol('Style', 'text','Position',  obj.Stxt_Pos, 'BackgroundColor', [0.8 0.8 0.8], 'FontSize', obj.SFntSz);

            obj.hButton_rangeReset = uicontrol('Style', 'pushbutton','Position', obj.Btn_Pos,'String','Reset W/L', 'FontSize', obj.BtnSz, 'Callback' , @obj.rangeReset);
            obj.hButton_View1 = uicontrol('Style', 'pushbutton','Position', obj.VAxBtn_Pos,'String','A', 'FontSize', obj.BtnSz, 'Callback' , @obj.AxialView);
            obj.hButton_View2 = uicontrol('Style', 'pushbutton','Position', obj.VSgBtn_Pos,'String','S', 'FontSize', obj.BtnSz, 'Callback' , @obj.SagittalView);
            obj.hButton_View3 = uicontrol('Style', 'pushbutton','Position', obj.VCrBtn_Pos,'String','C', 'FontSize', obj.BtnSz, 'Callback' , @obj.CoronalView);
            obj.hCheckBox = uicontrol('Style', 'checkbox','Position', obj.ChBx_Pos,'String','Fine Tune', 'BackgroundColor', [0.8 0.8 0.8], 'FontSize', obj.ChBxSz);
            obj.hText_Level = uicontrol('Style', 'text','Position', obj.Ltxt_Pos,'String','Level: ', 'BackgroundColor', [0.8 0.8 0.8], 'FontSize', obj.LFntSz);
            obj.hText_Window = uicontrol('Style', 'text','Position', obj.Wtxt_Pos,'String','Window: ', 'BackgroundColor', [0.8 0.8 0.8], 'FontSize', obj.WFntSz);
            obj.hValue_Level = uicontrol('Style', 'edit','Position', obj.Lval_Pos,'String','', 'BackgroundColor', [1 1 1], 'FontSize', obj.LVFntSz,'Callback', @obj.WinLevChanged);
            obj.hValue_Window = uicontrol('Style', 'edit','Position', obj.Wval_Pos,'String','', 'BackgroundColor', [1 1 1], 'FontSize', obj.WVFntSz,'Callback', @obj.WinLevChanged);
            obj.hText_View = uicontrol('Style', 'text','Position', obj.Vwtxt_Pos,'String','View: ', 'BackgroundColor', [0.8 0.8 0.8], 'FontSize', obj.LFntSz);

            set(obj.hFig, 'WindowScrollWheelFcn', @obj.mouseScroll);
            set(obj.hFig, 'ButtonDownFcn', @obj.mouseClick);
            set(get(obj.hAx,'Children'),'ButtonDownFcn', @obj.mouseClick);
            set(obj.hFig,'WindowButtonUpFcn', @obj.mouseRelease)
            set(obj.hFig,'ResizeFcn', @obj.figureResized)

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

            obj.sno = size(Img);  % image size
            obj.sno_a = obj.sno(3);  % number of axial slices
            obj.S_a = round(obj.sno_a/2);
            obj.sno_s = obj.sno(2);  % number of sagittal slices
            objS_s = round(obj.sno_s/2);
            obj.sno_c = obj.sno(1);  % number of coronal slices
            obj.S_c = round(obj.sno_c/2);
            obj.currentSlice = obj.S_a;
            obj.sno = obj.sno_a;
            obj.updateSliderScale

            obj.MinV = min(Img(:));
            obj.MaxV = max(Img(:));
            obj.LevV = (obj.MaxV + obj.MinV) / 2;
            obj.Win =  obj.MaxV - obj.MinV;

            % TODO: we can get rid of obj.LevV and obj.Win as this information is present in the string value
            obj.hValue_Level.String = obj.LevV;
            obj.hValue_Window.String = obj.Win;

            obj.imStackOrig = Img;
            obj.imStack = Img;


            if (nargin<3) || isempty(disprange)
                [obj.Rmin obj.Rmax] = windowLevel2Range(obj.Win, obj.LevV);
                obj.WinLevChanged
            else
                disp('Setting window level based on user-defined range')
                %TODO: probably redundant with obj.resetRange
                obj.LevV = mean(disprange);
                obj.Win = diff(disprange);
                [obj.Rmin obj.Rmax] = windowLevel2Range(obj.Win, obj.LevV);
           % set(obj.hValue_Level, 'String', sprintf('%6.0f',obj.LevV)); %TODO: this should be on a listener so it appears only once
            %set(obj.hValue_Window, 'String', sprintf('%6.0f',obj.Win));

            end

            obj.AxialView
        end %displayNewImageStack


        function displayImage(obj)
            imshow(squeeze(Img(:,:,obj.currentSlice,:)), [obj.Rmin obj.Rmax])
        end %display image



        function updateSliderScale(obj)
            % use current value of sno to update the slider text when there is an axis change
            if obj.sno > 1
                obj.hSlider.Max = obj.sno;
                obj.hSlider.Value = obj.currentSlice;
                obj.hSlider.SliderStep = [1/(obj.sno-1), 10/(obj.sno-1)];
            end
            obj.updateSliderText
        end

        function updateSliderText(obj)
            if obj.sno > 1
                set(obj.hSliderText, 'String', sprintf('Slice# %d / %d',obj.currentSlice, obj.sno));
            else
                set(obj.hSliderText, 'String', '2D image');
            end
        end

    end


    % Callbacks follow
    methods

        function figureResized(obj,~, eventdata)
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
            if obj.sno > 1
                obj.hSlider.Position=obj.slider_Pos;
            end
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


        function SliceSlider (obj,src,event)
            obj.currentSlice = round(get(src,'Value'));
            set(get(obj.hAx,'children'),'cdata',squeeze(obj.imStack(:,:,obj.currentSlice,:)))
            caxis([obj.Rmin obj.Rmax])
            obj.updateSliderText
        end


        function mouseScroll (obj,~, eventdata)
            UPDN = eventdata.VerticalScrollCount;
            obj.currentSlice = obj.currentSlice - UPDN;
            if (obj.currentSlice < 1)
                obj.currentSlice = 1;
            elseif (obj.currentSlice > obj.sno)
                obj.currentSlice = obj.sno;
            end

            %% TODO: the following is then repeated in a horrible way when switching axes
            if obj.sno > 1
                obj.hSlider.Value=obj.currentSlice;
            end
            obj.updateSliderText
            set(get(obj.hAx,'children'),'CData',squeeze(obj.imStack(:,:,obj.currentSlice,:)))
        end


        function mouseRelease (obj,~,eventdata)
            set(obj.hFig, 'WindowButtonMotionFcn', '')
        end


        function mouseClick (obj,~, eventdata)
            MouseStat = get(gcbf, 'SelectionType');
            if (MouseStat(1) == 'a')        %   RIGHT CLICK
                obj.InitialCoord = get(0,'PointerLocation');
                set(obj.hFig, 'WindowButtonMotionFcn', @obj.WinLevAdj);
            end
        end


        function WinLevAdj(obj,~,~)
            PosDiff = get(0,'PointerLocation') - obj.InitialCoord;
            obj.Win = obj.Win + PosDiff(1) * obj.LevelAdjustCoef * obj.FineTuneC(obj.hCheckBox.Value+1);
            obj.LevV = obj.LevV - PosDiff(2) * obj.LevelAdjustCoef * obj.FineTuneC(obj.hCheckBox.Value+1);
            if obj.Win<1
                obj.Win = 1;
            end
            [obj.Rmin, obj.Rmax] = windowLevel2Range(obj.Win,obj.LevV);

            caxis([obj.Rmin, obj.Rmax])
            set(obj.hValue_Level, 'String', sprintf('%6.0f',obj.LevV)); %TODO: this should be on a listener so it appears only once
            set(obj.hValue_Window, 'String', sprintf('%6.0f',obj.Win));
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


        function rangeReset(obj,~,eventdata)
            % This function is pretty useless: it just resets to the full range of the data
            obj.Win = range(obj.imStack(:));
            if obj.Win<1
                obj.Win = 1;
            end
            obj.LevV = double(min(obj.imStack(:)) + (obj.Win/2));
            [obj.Rmin, obj.Rmax] = windowLevel2Range(obj.Win,obj.LevV);
            caxis([obj.Rmin, obj.Rmax])
            set(obj.hValue_Level, 'String', sprintf('%6.0f',obj.LevV));
            set(obj.hValue_Window, 'String', sprintf('%6.0f',obj.Win));
        end



        % TODO: These three callbacks need to be refactored and merged into one
        function AxialView(obj,~,eventdata)
            if obj.View == 'S'
                obj.S_s = obj.currentSlice;
            elseif obj.View == 'C'
                obj.S_c = obj.currentSlice;
            end            
            obj.View = 'A';
            
            obj.imStack = obj.imStackOrig;
            obj.currentSlice = obj.S_a;
            obj.sno = obj.sno_a;
            cla(obj.hAx)
            imshow(squeeze(obj.imStack(:,:,obj.currentSlice,:)), [obj.Rmin obj.Rmax])

            obj.updateSliderScale
            
            caxis([obj.Rmin obj.Rmax])
            obj.updateSliderText
            
            set(get(obj.hAx,'children'),'cdata',squeeze(obj.imStack(:,:,obj.currentSlice,:)))
            set(obj.hFig, 'ButtonDownFcn', @obj.mouseClick);
            set(get(obj.hAx,'Children'),'ButtonDownFcn', @obj.mouseClick);
        end

        function SagittalView(obj,~,eventdata)
            if obj.View == 'A'
                obj.S_a = obj.currentSlice;
            elseif obj.View == 'C'
                obj.S_c = obj.currentSlice;
            end            
            obj.View = 'S';

            obj.imStack = flip(permute(obj.imStackOrig, [3 1 2 4]),1);   % Sagittal view image
            Sobj.currentSlice = obj.S_s;
            obj.sno = obj.sno_s;
            cla(obj.hAx)
            imshow(squeeze(obj.imStack(:,:,obj.currentSlice,:)), [obj.Rmin obj.Rmax])

            obj.updateSliderScale
            
            caxis([obj.Rmin obj.Rmax])
            obj.updateSliderText

            set(get(obj.hAx,'children'),'cdata',squeeze(obj.imStack(:,:,obj.currentSlice,:)))
            set(obj.hFig, 'ButtonDownFcn', @obj.mouseClick);
            set(get(obj.hAx,'Children'),'ButtonDownFcn', @obj.mouseClick);

        end

        function CoronalView(obj,~,eventdata)
            if obj.View == 'A'
                obj.S_a = obj.currentSlice;
            elseif obj.View == 'S'
                obj.S_s = obj.currentSlice;
            end            
            obj.View = 'C';
            
            obj.imStack = flip(permute(obj.imStackOrig, [3 2 1 4]),1); % Coronal view
            obj.currentSlice = obj.S_c;
            obj.sno = obj.sno_c;
            cla(obj.hAx)

            imshow(squeeze(obj.imStack(:,:,obj.currentSlice,:)), [obj.Rmin obj.Rmax])

            obj.updateSliderScale
            
            caxis([obj.Rmin obj.Rmax])
            obj.updateSliderText

            set(get(obj.hAx,'children'),'cdata',squeeze(obj.imStack(:,:,obj.currentSlice,:)))
            set(obj.hFig, 'ButtonDownFcn', @obj.mouseClick);
            set(get(obj.hAx,'Children'),'ButtonDownFcn', @obj.mouseClick);
        end

    end %methods

end