# movexml
move files xml services

# installation
open a dos command in admin mode
move to the service installation folder

type: movexml.exe /install an valid by return

go to system folder and open movexml.ini

[config]
path_system = folder where the xml file is localised
path_dest = folder where you want to move your files
log= true/false for active or deactive the traces

the service scan the path_system between 10 seconds

file unc are supported

if you have any question contact developper at : fdeprez@fdevelopment.eu

# compatibility

all version of Delphi XE nn

if you want to compile in older version of Delphi, changes the uses units
example: System.SysUtils by System
