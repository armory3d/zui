let project = new Project('CI');

project.addSources('Sources');
project.addAssets('../SharedAssets/DroidSans.ttf');
project.addLibrary('../../../zui');

resolve(project);
