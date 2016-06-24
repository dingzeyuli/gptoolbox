function [F,B,P] = readFACE(filename,varargin)
  % READFACE
  %
  %[F,B] = readFACE(filename)
  %
  % Read triangular faces from a .face file
  %
  % Input:
  %  filename  name of .face file
  %     Optional:
  %       'ForceNoBoundary' followed by true or false
  %       'ParentTetrahedra' followed by true or false. True if '-nn'
  %        option is used during tetgen.
  % Output:
  %  F  list of triangle indices
  %  B  list of boundary markers
  %

  force_no_boundary = false;
  parent_tetrahedra = false;
  element_order = 1;
  
  % default values
  % Map of parameter names to variable names
  params_to_variables = containers.Map( ...
    {'ForceNoBoundary', 'ParentTetrahedra', 'ElementOrder'}, ...
    {'force_no_boundary', 'parent_tetrahedra', 'element_order'} );
  v = 1;
  while v <= numel(varargin)
    param_name = varargin{v};
    if isKey(params_to_variables,param_name)
      assert(v+1<=numel(varargin));
      v = v+1;
      % Trick: use feval on anonymous function to use assignin to this workspace
      feval(@()assignin('caller',params_to_variables(param_name),varargin{v}));
    else
      error('Unsupported parameter: %s',varargin{v});
    end
    v=v+1;
  end

  
  fp = fopen(filename,'r');
  header = fscanf(fp,'%d %d\n',2);
  sizeF = header(1);
  boundary_markers = header(2);
  if force_no_boundary
    F = zeros(10000,3);
    f = 0;
    while true
      line = fgets(fp);
      if line == -1
        break;
      end
      if isempty(line)
        continue;
      end
      if line(1) == '#'
        continue
      end
      face = sscanf(line,'%d %d %d %d',4);
      f = f+1;
      % Resize
      if f>size(F,1)
        F = [F;zeros(size(F,1),size(F,2))];
      end
      F(f,:) = face(2:4);
    end
    F = F(1:f,:);
  else
    parser = '%d %d %d %d %d %d';
    num_items = 4;
    face_index_range = num_items;
    
    if (element_order == 2)
      parser = [parser ' %d %d %d'];
      num_items = num_items + 3;      
      face_index_range = num_items;
    end
      
    if (boundary_markers ~= 0)
      parser = [parser ' %d'];
      num_items = num_items + 1;
      boundary_range = num_items;
    end
    
    if parent_tetrahedra
      parser = [parser ' %d %d'];
      num_items = num_items + 2;
      parent_range = num_items;
    end
  
    F = fscanf(fp,parser,num_items*sizeF);
    fclose(fp);
  
    F = reshape(F,num_items,sizeF)';
    B = [];
    P = [];
    if boundary_markers
      B = F(:,boundary_range);
    end
    
    if parent_tetrahedra
      P = F(:,parent_range-1:parent_range);
    end
  
    % get rid of indices and boundary markers and make one indexed
    F = F(:,2: face_index_range);
  end
end
