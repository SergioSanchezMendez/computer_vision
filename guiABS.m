function guiABS
% guiABS permite la adaptación mediante interfaz
% gráfica de los valores de umbral y alfa del algoritmo
% de adaptative background substraction. Muestra los valores
% de la imagen original y la modificada.

   %  Create and hide the GUI as it is being constructed.
   f = figure('Visible','off','Position',[360,500,450,285]);
   
   %  Construct the components.
   %  Cuando se declaran los componentes se incluye la función de callback
   %  que se ejecutará cuando haya un evento. Serán de estructura estática.
   hsurf = uicontrol('Style','pushbutton','String','Surf',...
        'Position',[315,220,70,25],...
        'Callback',{@surfbutton_Callback});
      
   hmesh = uicontrol('Style','pushbutton','String','Mesh',...
           'Position',[315,180,70,25],...
            'Callback',{@meshbutton_Callback});
   hcontour = uicontrol('Style','pushbutton',...
           'String','Countour',...
           'Position',[315,135,70,25],...
           'Callback',{@contourbutton_Callback}); 
   htext = uicontrol('Style','text','String','Select Data',...
           'Position',[325,90,60,15]);
       
   hpopup = uicontrol('Style','popupmenu',...
           'String',{'Peaks','Membrane','Sinc'},...
           'Position',[300,50,100,25],...
           'Callback',{@popup_menu_Callback});
       
   ha = axes('Units','Pixels','Position',[50,60,200,185]); 
   align([hsurf,hmesh,hcontour,htext,hpopup],'Center','None');

    
   % Initialize the GUI.
    % Change units to normalized so components resize automatically.
    set([f,hsurf,hmesh,hcontour,htext,hpopup],'Units','normalized');
    % Generate the data to plot.
    peaks_data = peaks(35);
    membrane_data = membrane;
    [x,y] = meshgrid(-8:.5:8);
    r = sqrt(x.^2+y.^2) + eps;
    sinc_data = sin(r)./r;
    % Create a plot in the axes.
    current_data = peaks_data;
    surf(current_data);
    % Assign the GUI a name to appear in the window title.
    set(f,'Name','Simple GUI')
    % Move the GUI to the center of the screen.
    movegui(f,'center')
    % Make the GUI visible.
    set(f,'Visible','on');

    
    
    % Push button callbacks. Each callback plots current_data in the
    % specified plot type.

    function surfbutton_Callback(source,eventdata) 
    % Display surf plot of the currently selected data.
         surf(current_data);
    end

    function meshbutton_Callback(source,eventdata) 
    % Display mesh plot of the currently selected data.
         mesh(current_data);
    end

    function contourbutton_Callback(source,eventdata) 
    % Display contour plot of the currently selected data.
         contour(current_data);
    end
 
    
    

    %  Pop-up menu callback. Read the pop-up menu Value property to
    %  determine which item is currently displayed and make it the
    %  current data. This callback automatically has access to 
    %  current_data because this function is nested at a lower level.
       function popup_menu_Callback(source,eventdata) 
          % Determine the selected data set.
          str = get(source, 'String');
          val = get(source,'Value');
          % Set current data to the selected data set.
          switch str{val};
          case 'Peaks' % User selects Peaks.
             current_data = peaks_data;
          case 'Membrane' % User selects Membrane.
             current_data = membrane_data;
          case 'Sinc' % User selects Sinc.
             current_data = sinc_data;
          end
       end
      
    
    
    
    
end




    
    
