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

%include Animation.hpp
%include BasicTypes.hpp

namespace nifly {
  %template(ClonableHeaderObject) Clonable<NiHeader, NiObject>;
  %template(StreamableNodeAVObject) Streamable<NiNode, NiAVObject>;
  %template(ClonableShapeAVObject) Clonable<NiShape, NiAVObject>;
  %template(StreamableUnknownObject) Streamable<NiUnknown, NiObject>;
  %template(StreamableObjectNETObject) Streamable<NiObjectNET, NiObject>;
  %template(StreamableAVObjectObjectNET) Streamable<NiAVObject, NiObjectNET>;
};

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

namespace nifly {

  %template(StringExtraDataChildren) NifFile::GetChildren<NiStringExtraData>;
  %template(NodeChildren) NifFile::GetChildren<NiNode>;

  %template(NiNodeBlock) NiHeader::GetBlock<NiNode>;
  %template(NiAVObjectBlock) NiHeader::GetBlock<NiAVObject>;
  %template(NiPropertyBlock) NiHeader::GetBlock<NiProperty>;
};



%template(NiStringExtraDataVector) std::vector<nifly::NiStringExtraData*>;
%template(StringRefVector) std::vector<StringRef*>;

%template(BlockRefArrayNiAVObject) nifly::BlockRefArray<nifly::NiAVObject>;
%template(BlockRefNiAVObjectVector) std::vector<nifly::BlockRef<nifly::NiAVObject>>;
%template(BlockRefNiAVObject) nifly::BlockRef<nifly::NiAVObject>;

%template(BlockRefArrayNiProperty) nifly::BlockRefArray<nifly::NiProperty>;
%template(BlockRefNiPropertyVector) std::vector<nifly::BlockRef<nifly::NiProperty>>;
%template(BlockRefNiProperty) nifly::BlockRef<nifly::NiProperty>;

