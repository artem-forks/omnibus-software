# Copyright 2012-2018 Chef Software, Inc.
# Copyright 2018 Microsoft
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#######################################################################
#               MUSL libc software definition README                  #
#######################################################################
#
#   The musl (pronounced muscle) library is an alternative C library
# to glibc.
#
#   One may incorporate the musl linker into their omnibus build
# definitions in order to build universal linux packages which will be
# linked against the embedded musl-libc. As opposed to linking against
# the system glibc that may vary from platform to platform.
#
#   This is an easy way to create linux packages that have far greater
# portability across linux platforms than have been traditionally
# produced with omnibus. You may produce one binary artifact, with
# a singular build pipeline, that will run on all supported versions
# of Ubuntu and CentOS. As opposed to running a separate build
# pipeline for each platform and version which you intend to support.
#
#   In order to use the musl linker in your project, simply override
# the `CC` environment variable in your project definition(s) so that
# the musl-gcc wrapper takes action to link all the C code in your
# project against the musl-libc libraries.  The below snippet will
# need to be invoked before any dependencies in your project that
# compile C code. Note that the musl-gcc wrapper is dependent on
# having a system gcc in-place. This software definition is
# dependent on the gcc location being symlinked, or installed, at
# `/usr/bin/gcc`.
#
#  Example project definition override:
#
#    if linux?
#      ENV['CC'] = "#{install_dir}/embedded/bin/musl-gcc"
#      dependency 'musl'
#    end
#
#  How that works:
#
# 1. Set `CC` equal to the embedded musl-gcc wrapper in project
#    definition. e.g. chef-workstation
#
# 2. The musl software definition overrides `CC=/usr/bin/gcc` and
#    builds musl-libc and installs in $install_dir/embedded.
#    e.g. /opt/chef/embedded/(lib|bin)
#
# 3. Software definition (e.g. ruby) picks up `CC` environment
#    variable from project definition and uses the embedded musl-gcc
#    wrapper to link the code against the embedded musl libraries.
#
#####################################################################

name "musl"
default_version "1.1.20"

license "MIT"
license_file "COPYRIGHT"

version("1.1.19") { source sha256: "db59a8578226b98373f5b27e61f0dd29ad2456f4aa9cec587ba8c24508e4c1d9" }
version("1.1.20") { source sha256: "44be8771d0e6c6b5f82dd15662eb2957c9a3173a19a8b49966ac0542bbd40d61" }

source url: "https://www.musl-libc.org/releases/musl-#{version}.tar.gz"

relative_path "musl-#{version}"

build do
  # The musl definition must be compiled with a system
  # This isn't a self-hosting build definition wherein
  # musl compiles itself.
  env = with_standard_compiler_flags(with_embedded_path)
  env["CC"] = "/usr/bin/gcc"

  command "./configure" \
          " --prefix=#{install_dir}/embedded" \
          " --syslibdir=#{install_dir}/embedded/lib", env: env

  make env: env
  make "install", env: env

  # Ruby compilation requires the linux kernel headers to be in the
  # same location as the Libc headers. For this to work correctly
  # will need to have a kernel-dev(el) package installed on your
  # omnibus builder.
  %w{asm asm-generic linux}.each do |d|
    copy "/usr/include/#{d}", "#{install_dir}/embedded/include"
  end
end
