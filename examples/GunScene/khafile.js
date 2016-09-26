let project = new Project('Elements');

project.addSources('Sources');
project.addAssets('Assets/**');
project.addAssets('../SharedAssets/**');
project.addLibrary('../../../../zui');

resolve(project);
