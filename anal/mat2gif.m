function mat2gif(varargin)

getArgs(varargin,{'filename=sari'});

giffilename = [filename,'.gif'];

data = load([filename,'.mat']);

for ii = 1:length(data.im)

  [imind,cm] = rgb2ind(data.im(ii).cdata,256); 
  % Write to the GIF File 
  if ii == 1 
      imwrite(imind,cm,giffilename,'gif', 'Loopcount',inf); 
  else 
      imwrite(imind,cm,giffilename,'gif','WriteMode','append'); 
  end 
end