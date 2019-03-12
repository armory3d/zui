let project = new Project('Elements');

project.addSources('Sources');
project.addAssets('../SharedAssets/DroidSans.ttf');
project.addLibrary('../../../../zui');

resolve(project);
