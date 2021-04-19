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
%include "std_set.i"

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

  // Generalized getters, exact derived class not important
  %template(NiNodeBlock) NiHeader::GetBlock<NiNode>;
  %template(NiAVObjectBlock) NiHeader::GetBlock<NiAVObject>;
  %template(NiPropertyBlock) NiHeader::GetBlock<NiProperty>;
  %template(NiShaderBlock) NiHeader::GetBlock<NiShader>;

  // precise getters, where exact type match is essential to avoid slicing in C++ -> C# conversion
  %template(BSTriShapeBlockPrecise) NiHeader::GetBlockPrecise<BSTriShape>;
  %template(NiTriShapeBlockPrecise) NiHeader::GetBlockPrecise<NiTriShape>;
  %template(NiTriStripsBlockPrecise) NiHeader::GetBlockPrecise<NiTriStrips>;
  %template(BSDynamicTriShapeBlockPrecise) NiHeader::GetBlockPrecise<BSDynamicTriShape>;
  %template(BSDismemberSkinInstanceBlockPrecise) NiHeader::GetBlockPrecise<BSDismemberSkinInstance>;

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

%template(RefSet) std::set<nifly::NiRef*>;

%template(BlockRefAdditionalGeomData) nifly::NiBlockRef<nifly::AdditionalGeomData>;
%template(BlockRefbhkCompressedMeshShapeData) nifly::NiBlockRef<nifly::bhkCompressedMeshShapeData>;
%template(BlockRefbhkShape) nifly::NiBlockRef<nifly::bhkShape>;
%template(BlockRefBSAnimNotes) nifly::NiBlockRef<nifly::BSAnimNotes>;
%template(BlockRefBSMultiBound) nifly::NiBlockRef<nifly::BSMultiBound>;
%template(BlockRefBSMultiBoundData) nifly::NiBlockRef<nifly::BSMultiBoundData>;
%template(BlockRefBSShaderProperty) nifly::NiBlockRef<nifly::BSShaderProperty>;
%template(BlockRefBSShaderTextureSet) nifly::NiBlockRef<nifly::BSShaderTextureSet>;
%template(BlockRefBSSkinBoneData) nifly::NiBlockRef<nifly::BSSkinBoneData>;
%template(BlockRefhkPackedNiTriStripsData) nifly::NiBlockRef<nifly::hkPackedNiTriStripsData>;
%template(BlockRefNiAlphaProperty) nifly::NiBlockRef<nifly::NiAlphaProperty>;
%template(BlockRefNiBoneContainer) nifly::NiBlockRef<nifly::NiBoneContainer>;
%template(BlockRefNiBoolData) nifly::NiBlockRef<nifly::NiBoolData>;
%template(BlockRefNiBSplineBasisData) nifly::NiBlockRef<nifly::NiBSplineBasisData>;
%template(BlockRefNiBSplineData) nifly::NiBlockRef<nifly::NiBSplineData>;
%template(BlockRefNiCollisionObject) nifly::NiBlockRef<nifly::NiCollisionObject>;
%template(BlockRefNiColorData) nifly::NiBlockRef<nifly::NiColorData>;
%template(BlockRefNiDefaultAVObjectPalette) nifly::NiBlockRef<nifly::NiDefaultAVObjectPalette>;
%template(BlockRefNiFloatData) nifly::NiBlockRef<nifly::NiFloatData>;
%template(BlockRefNiFloatInterpolator) nifly::NiBlockRef<nifly::NiFloatInterpolator>;
%template(BlockRefNiGeometryData) nifly::NiBlockRef<nifly::NiGeometryData>;
%template(BlockRefNiInterpController) nifly::NiBlockRef<nifly::NiInterpController>;
%template(BlockRefNiLODData) nifly::NiBlockRef<nifly::NiLODData>;
%template(BlockRefNiMorphData) nifly::NiBlockRef<nifly::NiMorphData>;
%template(BlockRefNiNode) nifly::NiBlockRef<nifly::NiNode>;
%template(BlockRefNiObject) nifly::NiBlockRef<nifly::NiObject>;
%template(BlockRefNiPalette) nifly::NiBlockRef<nifly::NiPalette>;
%template(BlockRefNiPoint3Interpolator) nifly::NiBlockRef<nifly::NiPoint3Interpolator>;
%template(BlockRefNiPosData) nifly::NiBlockRef<nifly::NiPosData>;
%template(BlockRefNiProperty) nifly::NiBlockRef<nifly::NiProperty>;
%template(BlockRefNiPSysCollider) nifly::NiBlockRef<nifly::NiPSysCollider>;
%template(BlockRefNiPSysData) nifly::NiBlockRef<nifly::NiPSysData>;
%template(BlockRefNiPSysModifier) nifly::NiBlockRef<nifly::NiPSysModifier>;
%template(BlockRefNiPSysSpawnModifier) nifly::NiBlockRef<nifly::NiPSysSpawnModifier>;
%template(BlockRefNiShader) nifly::NiBlockRef<nifly::NiShader>;
%template(BlockRefNiSkinData) nifly::NiBlockRef<nifly::NiSkinData>;
%template(BlockRefNiSkinPartition) nifly::NiBlockRef<nifly::NiSkinPartition>;
%template(BlockRefNiSourceTexture) nifly::NiBlockRef<nifly::NiSourceTexture>;
%template(BlockRefNiTextKeyExtraData) nifly::NiBlockRef<nifly::NiTextKeyExtraData>;
%template(BlockRefNiTimeController) nifly::NiBlockRef<nifly::NiTimeController>;
%template(BlockRefNiTransformData) nifly::NiBlockRef<nifly::NiTransformData>;
%template(BlockRefNiUVData) nifly::NiBlockRef<nifly::NiUVData>;
%template(BlockRefTextureRenderData) nifly::NiBlockRef<nifly::TextureRenderData>;

%template(vectorBSSITSSubSegment) std::vector<nifly::BSSubIndexTriShape::BSSITSSubSegment>;
%template(vectorBSVertexData) std::vector<nifly::BSVertexData>;
%template(vectorColor4) std::vector<nifly::Color4>;
%template(vectorNifSegmentInfo) std::vector<nifly::NifSegmentInfo>;
%template(vectorTriangle) std::vector<nifly::Triangle>;
%template(vectorVector2) std::vector<nifly::Vector2>;
%template(vectorVector3) std::vector<nifly::Vector3>;
