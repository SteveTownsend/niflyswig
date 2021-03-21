// File : niflycpp.i
%module niflycpp

%{
#include "Animation.hpp"
#include "BasicTypes.hpp"
#include "bhk.hpp"
#include "ExtraData.hpp"
#include "Factory.hpp"
#include "Geometry.hpp"
#include "KDMatcher.hpp"
#include "Keys.hpp"
#include "NifFile.hpp"
#include "NifUtil.hpp"
#include "Nodes.hpp"
#include "Object3d.hpp"
#include "Objects.hpp"
#include "Particles.hpp"
#include "Shaders.hpp"
#include "Skin.hpp"
#include "VertexData.hpp"

using namespace nifly;
%}

%include "stdint.i"
%include "std_string.i"
%include "std_vector.i"

namespace std {
  %template(vectoru16) vector<uint16_t>;
  %template(vectoru32) vector<uint32_t>;
  %template(vectoru64) vector<uint64_t>;
  %template(vectorf) vector<float>;
};

%include Animation.hpp
%include BasicTypes.hpp
%include bhk.hpp
%include ExtraData.hpp
%include Factory.hpp
%include Geometry.hpp
%include KDMatcher.hpp
%include Keys.hpp
%include NifFile.hpp
%include NifUtil.hpp
%include Nodes.hpp
%include Object3d.hpp
%include Objects.hpp
%include Particles.hpp
%include Shaders.hpp
%include Skin.hpp
%include VertexData.hpp
