let project = new Project('Elements');

project.addSources('Sources');
project.addAssets('../SharedAssets/DroidSans.ttf');
project.addAssets('../SharedAssets/color_wheel.png');
project.addAssets('../SharedAssets/black_white_gradient.png');
project.addLibrary('../../../../zui');

resolve(project);
