var project = new Project('Empty');

project.addSources('Sources');
project.addAssets('Assets/**');
project.addLibrary('zui');

return project;
