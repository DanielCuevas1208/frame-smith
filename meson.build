project('framesmith', ['vala', 'c'],
  version: '0.1.0',
  license: 'MIT',
  meson_version: '>= 0.61.0',
  default_options: ['warning_level=2'])

glib = dependency('glib-2.0', version: '>= 2.56')
gobject = dependency('gobject-2.0', version: '>= 2.56')
gdkpixbuf = dependency('gdk-pixbuf-2.0', version: '>= 2.40')
gtk = dependency('gtk+-3.0', version: '>= 3.22')

core_deps = [glib, gobject, gdkpixbuf]

core_sources = files(
  'src/libframesmith/image.vala',
  'src/libframesmith/convolution.vala',
  'src/libframesmith/filters.vala',
  'src/libframesmith/chain.vala',
  'src/libframesmith/histogram.vala',
  'src/libframesmith/pixbuf_io.vala',
)

app_sources = files(
  'src/framesmith/app.vala',
  'src/framesmith/window.vala',
  'src/framesmith/histogram_widget.vala',
)

vala_args = ['--fatal-warnings']

framesmith = executable('framesmith',
  app_sources + core_sources,
  dependencies: [gtk] + core_deps,
  vala_args: vala_args,
  install: true)

core_test = executable('test-core',
  files('tests/harness.vala', 'tests/core_tests.vala') + core_sources,
  dependencies: core_deps,
  vala_args: vala_args)

io_test = executable('test-io',
  files('tests/harness.vala', 'tests/io_tests.vala') + core_sources,
  dependencies: core_deps,
  vala_args: vala_args)

test('core', core_test)

test('io', io_test,
  args: [join_paths(meson.project_source_root(), 'data', 'sample.png')])

bindir_conf = configuration_data()
bindir_conf.set('bindir', join_paths(get_option('prefix'), get_option('bindir')))

configure_file(
  input: 'data/org.framesmith.FrameSmith.desktop.in',
  output: 'org.framesmith.FrameSmith.desktop',
  configuration: bindir_conf,
  install_dir: join_paths(get_option('datadir'), 'applications'),
)

install_data('data/icons/org.framesmith.FrameSmith.svg',
  install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps'))
