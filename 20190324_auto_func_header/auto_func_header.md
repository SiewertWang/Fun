
# 懒人的matlab自定义函数指南

>六个月前，我写了某个matlab脚本处理数据；
>
>三个月前，我加了一行function把它改成了函数；
>
>今天上午，我的师兄找我要了这个函数；
>
>五分钟前，我的师兄提着刀来找你了；
>
>为什么？
>
>因为我没写注释。

这里是一种很常见场景，我们开始做一个工作的时候，常常最开始写的就是一个脚本，经过一番测试之后可能会改成函数方便以后重复调用，比如我们从unsplash下载猫片的函数。测试脚本的时候，往往为了快速推进，一般写的都是行内的注释，而不去关心文件头的注释。而改成函数的时候，matlab只需要你在头上加上function声明语句，然后把输入输出变量设定好就ok了。像我这样懒的人，一般这时候就略过了写函数头注释的步骤，给自己埋下一个雷。

函数头的注释和普通行内注释不同，它并不仔细解释代码是如何运行的，而是解释代码应该如何使用，在命令行输入help + 函数名，返回的就是文件头注释，或者说，函数头实际上是帮助文档。

## 函数头结构
我们先来看看matlab的函数头一般包含什么信息，以linspace函数为例：

```matlab
function y = linspace(d1, d2, n)
%LINSPACE Linearly spaced vector.
%   LINSPACE(X1, X2) generates a row vector of 100 linearly
%   equally spaced points between X1 and X2.
%
%   LINSPACE(X1, X2, N) generates N points between X1 and X2.
%   For N = 1, LINSPACE returns X2.
%
%   Class support for inputs X1,X2:
%      float: double, single
%
%   See also LOGSPACE, COLON.

%   Copyright 1984-2016 The MathWorks, Inc.
```
这里包含了：
* 函数声明
* 函数概述
* 函数语法
* 输入参数说明
* 依赖关系
* 版权信息

对于不同的机构/个人，函数头的布局规范可能会有所不同，强调的内容也会有所不同。比如下面这个是我常用的文件头

```matlab
function [output1,output2,varargout] = myfun(input1,input2,input3,varargin)
%MYFUN - One line description
%More detailed description goes here
%
% Syntax:  [output1,output2,varargout] = myfun(input1,input2,input3,varargin)
%
% Inputs:
%  required:
%    input1 - Description
%    input2 - Description
%    input3 - Description
%  optional:
%       varargin
%
% Outputs:
%    output1 - Description
%    output2 - Description
%  optional:
%       varargout
%
% Example: 
%    Line 1 of example
%    Line 2 of example
%    Line 3 of example
%
% See also: OTHER_FUNCTION_NAME1,  OTHER_FUNCTION_NAME2
%
% Reference:
 
% Author: John Doe (JD)
% Created: 23-Mar-2019
% Revision: 
```

跟matlab的函数头相比，我弱化了对于Syntax组合的描述，而细化了对于每个输入输出参数的描述，同时增加了可变长度输入参数的选项，此外还增加了例子，Reference信息，以及函数日志信息。

## 自动生成函数头
为了保证代码之间的风格统一性，同时又节省时间，最好的办法就是使用文件头模板，你可以自己建一个.m文件，每次复制文件头填上具体函数信息即可。但是懒人仍然觉得这样有点麻烦，又提出了新的需求
* 不同风格的函数头，比如
    * 紧凑型：只有最基本的注释
    * 扩展型：包含尽可能多的信息，包含可变输入参数的解析
* 自动检查matlab路径里是否有重名的函数
* 自动填充函数名/生成日期/作者信息
* 自动匹配输入输出参数个数

有了这些需求，那么每次复制粘贴是不太好使了。解决方案当然是：写一个函数，生成函数头。这个函数我们叫它CreateFunction。

### 必选输入参数
最小必选输入参数应该包含要创建的函数名，而输出应该是写入一个.m文件，不用返回值，所以，最基本的调用这个函数的语法可以是：
```matlab
CreateFunction('MyFunction')
```
相应的，必选的参数在声明函数的时候应该明确的写出来
```matlab
function CreateFunction(fname)
```

### 可选输入参数
可选输入参数使得懒人和勤快人都得到满足，比如说，我们可能希望把这个新建的函数放到某个专门存放自定义函数的地方而不是当前文件夹，这时候我们可以把函数的存放路径作为可选参数，如果不输入任何值，那么就在当前目录生成这个函数，调用的时候可以是：
```matlab
CreateFunction('MyFunction')
CreateFunction('MyFunction','c:\bin\matlab\')
```
那么这一功能如何在函数声明以及主体中实现呢？在matlab中有两种办法实现它，一种是在函数声明的时候我们需要包含所有输入参数，也就是说：
```matlab
function CreateFunction(fname，fpath)
```
然后在函数主体中，我们加入语句来判断输入参数fpath是否合法。
```matlab
if nargin < 2 | strcmp(fpath,'')
    fpath = '.'
end
```
这里相当于，我们假设了fpath是必选输入参数，但是在函数主体中通过判断语句，来判断是否输入了fpath或者fpath是否是空字符，从而在必要的时候赋予它默认值。

另一种做法是使用输入参数解析器inputParser，我们平时调用plot函数，输入以下任何情况都不会报错
```matlab
plot(Y)
plot(X,Y)
plot(X,Y,'r-')
plot(X,Y,'linewidth',1.5)
```
输入参数解析器使得输入任意长度的参数列表都能过被matlab接受。对于CreateFunction，这时函数声明变成：
```matlab
function CreateFunction(fname，varargin)
```
在函数主体中对varargin，进行解析
```matlab
p = inputParser;

addRequired(p,'fname',@ischar);
addOptional(p,'fpath','.',@ischar);

parse(p,fname,varargin{:});
fname = p.Results.fname;
fpath = p.Restults.fpath;
```
这里首先要创建解析器对象，然后按照必选-可选-参数对的顺序加入到解析器中，同时这里还需要声明默认值，以及验证输入参数的合法性（我们这里要求输入的fname，fpath必须是字符串），随后对参数进行解析，并取出解析结果。对于比较简单的函数，一般不需要使用解析器，对于更为复杂的输入参数，特别是由变量名+值组成的参数对的时候，使用解析器就显得很有必要。


前面提到可能希望函数头有不同的详细程度，那么我们可以把这一需求当作可变输入参数来实现。我们把这个参数名叫做'style',而它有三种可选值'compact','standard' (默认值),'extended'，这时我们调用的时候可以是
```matlab
CreateFunction('MyFunction')
CreateFunction('MyFunction','.','style','compact')
CreateFunction('MyFunction','.','style','standard')
CreateFunction('MyFunction','.','style','extended')
CreateFunction('MyFunction','c:\bin\matlab','style','extended')
```


注意这里尽管fpath是可选参数，但是MATLAB的parse太弱鸡，如果省掉fpath输入，则'style'会被解析成fpath，而'compact'会被解析成一个变量名，从而报错。因此，这里必须要输入fpath。
```matlab
function CreateFunction(fname，varargin)
```

在函数主体中对varargin，进行解析
```matlab
p = inputParser;

validStyle = {'compact','standard','extended'};

addRequired(p,'fname',@ischar);
addOptional(p,'fpath','.',@(x) ischar(x));
addParameter(p,'style','standard',@(x) any(validatestring(x,validStyle)));

parse(p,fname,varargin{:});
fname = p.Results.fname;
fpath = p.Restults.fpath;
style = p.Restults.style;
```
这里，style按照AddPatameter的方式添加到解析器中，并且设定了只有三种合法值。


### 其他
可选参数搞定之后，其他的就比较容易了
* 如果fname没有.m，则自动添加.m，简单的用一个strfind就行了，或者用牛刀：regexp
* 检查当前系统路径有没有重名函数，有则返回错误信息
* 如果输入路径有错，则弹出路径选择对话框，用try catch语句以及uigetdir
* 自动填充日期，函数名，作者等

## 测试函数

是的，函数我给你们写好了。来测试一番吧。



```matlab
%CreateFunction('test1')
%CreateFunction('test1')   % will get an error since test1.m already created
%mkdir('sub')
%CreateFunction('test2','sub')  % create in a different path
%CreateFunction('test2','sub2')  % create in a non-existent path, will popup at window

% will get an error since parser interpret 'style' as fpath, and compact as name of name-value pair
%CreateFunction('test3','style','compact')  

% correct way of optional + name-value pair 
%CreateFunction('test3','.','style','compact')  
%CreateFunction('test4','.','style','standard')
%CreateFunction('test5','.','style','extended')

```

    
    
