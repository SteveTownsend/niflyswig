// File : niflycpp.i
//
// niflysharp
// C# NIF library for the Gamebryo/NetImmerse File Format
// See the included GPLv3 LICENSE file
//
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

%include BasicTypes.hpp
%include Objects.hpp
%include Nodes.hpp
%include Animation.hpp
%include bhk.hpp
%include ExtraData.hpp
%include Factory.hpp
%include Geometry.hpp
%include KDMatcher.hpp
%include Keys.hpp
%include NifFile.hpp
%include NifUtil.hpp
%include Object3d.hpp
%include Particles.hpp
%include Shaders.hpp
%include Skin.hpp
%include VertexData.hpp

namespace nifly {
  %template(StringExtraDataChildren) NifFile::GetChildren<NiStringExtraData>;

  %template(NiNodeBlock) NiHeader::GetBlock<NiNode>;
  %template(NiAVObjectBlock) NiHeader::GetBlock<NiAVObject>;
  %template(NiPropertyBlock) NiHeader::GetBlock<NiProperty>;

  %template(CreateNamedBSFadeNode) NifFile::CreateNamed<BSFadeNode>;
};

// helpers for NiStringRef list retrieval
%template(StringRefVectorBase) nifly::NiVectorBase<nifly::NiStringRef, uint32_t>;
%template(StringRefVector) nifly::NiStringRefVector<uint32_t>;
%template(StringRefPointerVector) std::vector<nifly::NiStringRef*>;

%template(BlockRefArrayAVObject) nifly::NiBlockRefArray<nifly::NiAVObject>;
%template(BlockRefAVObjectVector) std::vector<nifly::NiBlockRef<nifly::NiAVObject>>;
%template(BlockRefAVObject) nifly::NiBlockRef<nifly::NiAVObject>;

%template(BlockRefArrayProperty) nifly::NiBlockRefArray<nifly::NiProperty>;
%template(BlockRefPropertyVector) std::vector<nifly::NiBlockRef<nifly::NiProperty>>;
%template(BlockRefProperty) nifly::NiBlockRef<nifly::NiProperty>;

%template(BlockRefArrayExtraData) nifly::NiBlockRefArray<nifly::NiExtraData>;

%template(StringExtraDataVector)  std::vector<nifly::NiStringExtraData*>;
