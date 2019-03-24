function [] = CreateFunction(fname,varargin)

% parse the input
p = inputParser;

validStyle = {'compact','standard','extended'};

addRequired(p,'fname',@(x)ischar(x));
addOptional(p,'fpath',pwd,@(x)ischar(x));
addParameter(p,'style','standard',@(x)any(validatestring(x,validStyle)));

% note: in the case of: an optional string + name-value pair, MATLAB parser 
%       does not perform well, MATLAB, since it misinterprets the optional 
%       input string as name of a name-value pair. Seem to be a bug.
%  1. validate function for the optional string should be: @(x) ischar(x),
%       not just @ischar
%  2. Do not omit the optional string when call the function, i.e.,
%     DO NOT USE: CreateFunction(fname,'key1','val1')
%     Should USE: CreateFunction(fname,fpath,'key1','val1')
%     in the case, it is not optional at all.
% 
parse(p,fname,varargin{:});
fname = p.Results.fname;
fpath = p.Results.fpath;
style = p.Results.style;

%  preparation
x = regexpi(fname,'\.m');
if isempty(x)
    rname = fname;
    fname = [fname '.m'];    % add .m if not included in fname
else
    rname = fname(1:x-1);    % if has .m, strip it, for use in header
end

if ~isempty(which(fname))    % if function exist in path, raise an error
    error(['Function ' fname ' already exist!'])  
end

% catch file open error
try 
    fullname = [fpath '\' fname];       
    fid = fopen(fullname,'w+');
    if fid == -1
        error;
    end
catch
    fpath = uigetdir();
    fullname = [fpath '\' fname];
    fid = fopen(fullname,'w+');
end

% number of input & output arguments
if strcmp(style,'compact')
    Ninput = 1;
    Noutput = 1;
else
    Ninput = 3;
    Noutput = 2;
end

% create string for input & output list
for ii = 1:Ninput
    intmp{ii} = ['input' num2str(ii)];
end
instr = strjoin(intmp,',');

for ii = 1:Noutput
    outtmp{ii} = ['output' num2str(ii)];
end
outstr = strjoin(outtmp,',');
clear intmp outtmp

% write to file
fprintf(fid,'function [%s,varargout] = %s(%s,varargin)\n',outstr,rname,instr);
fprintf(fid,'%%%s - One line description\n',upper(rname));
fprintf(fid,'%%More detailed description goes here\n%%\n');
fprintf(fid,'%% Syntax:  [%s,varargout] = %s(%s,varargin)\n%%\n',outstr,rname,instr);
fprintf(fid,'%% Inputs:\n');
for ii = 1:Ninput
    fprintf(fid,'%%    input%d - Description, data type, data units\n',ii);
end
fprintf(fid,'%%  optional:\n');
fprintf(fid,'%%       varargin\n%%\n');
fprintf(fid,'%% Outputs:\n');
for ii = 1:Noutput
    fprintf(fid,'%%    output%d - Description, data type, data units\n',ii);
end
fprintf(fid,'%%  optional:\n');
fprintf(fid,'%%       varargout\n%%\n');

if strcmp(style,'extended') | strcmp(style,'standard')
    fprintf(fid,'%% Example: \n');
    fprintf(fid,'%%    Line 1 of example\n');
    fprintf(fid,'%%    Line 2 of example\n');
    fprintf(fid,'%%    Line 3 of example\n%%\n');
    fprintf(fid,'%% See also: OTHER_FUNCTION_NAME1,  OTHER_FUNCTION_NAME2\n%%\n');
    fprintf(fid,'%% Reference:\n\n');
end

fprintf(fid,'%% Author: Siewert Wang (SW)\n');
fprintf(fid,'%% Created: %s\n',date);
fprintf(fid,'%% Revision notes: \n\n');
if strcmp(style,'extended')
    fprintf(fid,'%% parse the inputs\n');
    fprintf(fid,'p = inputParser;\n\n');
    for ii = 1:Ninput
        fprintf(fid,'addRequired(p,''input%d'',@validinput%d)\n',ii,ii);
    end
    fprintf(fid,'addOptional(p,''optinput'',optdefault,@validoptinput)\n');
    fprintf(fid,'addParameter(p,''key'',valdefault,@validparinput)\n\n');
    
    fprintf(fid,'parse(p,%s,varargin{:});',instr);
    for ii = 1:Ninput
        fprintf(fid,'input%d = p.Results.input%d;\n',ii,ii);
    end
    fprintf(fid,'optinput = p.Results.optinput;\n');
    fprintf(fid,'key = p.Results.key;\n\n');
    
end

fprintf(fid,'%% ------------- CODE BEGINS --------------\n');
fprintf(fid,'%% CODING HERE\n');
fprintf(fid,'%% ------------- CODE ENDS --------------\n');
fclose(fid);
    
% ------------------- CODE ENDS ----------------------