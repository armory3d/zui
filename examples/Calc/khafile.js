var project = new Project('Elements');

project.addSources('Sources');
project.addAssets('../SharedAssets/**');
project.addLibrary('../../../../zui');

return project;
