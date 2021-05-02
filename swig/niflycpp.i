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
%include "std_array.i"
%include "std_deque.i"

%apply const std::string & {std::string &};

namespace std {
  %template(arrayuint16_6) array<uint16_t, 6>;
  %template(arrayuint8_3) array<uint8_t, 3>;
  %template(arrayuint8_4) array<uint8_t, 4>;
  %template(arrayfloat_4) array<float, 4>;
  %template(arrayfloat_6) array<float, 6>;
  %template(arrayfloat_12) array<float, 12>;
  %template(arrayfloat_16) array<float, 16>;

  %template(dequebool) deque<bool>;

  %template(vector2Dint) vector<vector<int>>;
  %template(vector2Duint16) vector<vector<uint16_t>>;
  %template(vector2Duchar) vector<vector<unsigned char>>;
  %template(vectorchar) vector<char>;
  %template(vectorfloat) vector<float>;
  %template(vectorint) vector<int>;
  %template(vectorstring) vector<string>;
  %template(vectoruchar) vector<unsigned char>;
  %template(vectoruint16) vector<uint16_t>;
  %template(vectoruint32) vector<uint32_t>;
  %template(vectoruint64) vector<uint64_t>;
  %template(vectorshort) vector<short>;
};

%include "typemaps.i"

%define %standard_byref_param(TYPE)
  %apply TYPE& INOUT { TYPE& };
%enddef
%standard_byref_param(int)
%standard_byref_param(float)

%typemap(csout, excode=SWIGEXCODE)
  nifly::NiObject *
{
    System.IntPtr cPtr = $imcall;
    $csclassname ret = ($csclassname) $modulePINVOKE.instantiateConcreteNiObject(cPtr, $owner);$excode
    return ret;
}

%pragma(csharp) modulecode=%{
    public class BlockCache : System.IDisposable
    {
        public NiHeader Header { get; }
        public System.Collections.Generic.IDictionary<int, NiObject> blockEdit = new System.Collections.Generic.Dictionary<int, NiObject>();

        public BlockCache(NiHeader header)
        {
            Header = header;
        }
        public void Dispose()
        {
            ClearEditableBlocks();
            Header.Dispose();
        }

        // Clone any NiObject as its most derived type to avoid slicing in the SWIG layer
        static public T SafeClone<T>(NiObject block) where T : NiObject
        {
            return (T)block.GetType().GetMethod("Clone").Invoke(block, null);
        }

        public T TryGetEditableBlockById<T>(int blockId) where T : NiObject
        {
            T result = null;
            NiObject edited = null;
            if (blockEdit.TryGetValue(blockId, out edited))
            {
                result = edited as T;
            }
            return result;
        }

        // Produce a cloned view of an underlying block for safe editing and later persistence to a new NifFile
        public T EditableBlockById<T>(int blockId) where T : NiObject
        {
            T result = TryGetEditableBlockById<T>(blockId);
            if (result == null)
            {
                result = Header.GetBlockById(blockId) as T;
                if (result != null)
                {
                result = SafeClone<T>(result);
                if (result != null)
                {
                    blockEdit[blockId] = result;
                }
                }
            }
            return result;
        }

        public void ClearEditableBlocks()
        {
            foreach (var idBlock in blockEdit)
            {
                idBlock.Value.Dispose();
            }
            blockEdit.Clear();
        }
    }

    public class TextureFinder : System.IDisposable
    {
        private BlockCache blockCache;
        private System.Collections.Generic.ISet<string>? uniqueTextures;

        public TextureFinder(NiHeader target)
        {
            blockCache = new BlockCache(BlockCache.SafeClone<NiHeader>(target));
        }

        public void Dispose()
        {
            blockCache.Dispose();
        }

        public System.Collections.Generic.IEnumerable<string> UniqueTextures
        {
            get
            {
                if (uniqueTextures == null)
                {
                    uniqueTextures = new System.Collections.Generic.HashSet<string>();
                    for (int blockId = 0; blockId < blockCache.Header.GetNumBlocks(); ++blockId)
                    {
                        BSShaderTextureSet textureSet = blockCache.EditableBlockById<BSShaderTextureSet>(blockId);
                        if (textureSet != null)
                        {
                            using var textures = textureSet.textures;
                            using var texturePaths = textures.items();
                            foreach (NiString texture in texturePaths)
                            {
                                using (texture)
                                {
                                    if (texture != null)
                                    {
                                        string texturePath = texture.get();
                                        if (System.String.IsNullOrEmpty(texturePath))
                                        {
                                            uniqueTextures.Add(texturePath);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                return uniqueTextures;
            }
        }
    }
%}
 
%typemap(csclassmodifiers) nifly::NifFile "public partial class";

%typemap(cscode) nifly::NifFile %{
    public static void CheckDestinationExists(string destDir)
    {
        if (!System.IO.Directory.Exists(destDir))
        {
            System.IO.Directory.CreateDirectory(destDir);
        }
    }

    public int SafeSave(string fileName, NifSaveOptions options)
    {
        CheckDestinationExists(System.IO.Path.GetDirectoryName(fileName)!);
        return Save(fileName, options);
    }
%}

// Object3D operators, mostly
%rename(opAdd) *::operator+;
%rename(opDiv) *::operator/;
%rename(opEq) *::operator==;
%rename(opLt) *::operator<;
%rename(opMult) *::operator*;
%rename(opNeq) *::operator!=;
%rename(opSub) *::operator-;

%include Object3d.hpp
%include BasicTypes.hpp
%include Keys.hpp
%include Objects.hpp
%include Shaders.hpp
%include Nodes.hpp
%include VertexData.hpp
%include Geometry.hpp
%include Animation.hpp
%include ExtraData.hpp
%include bhk.hpp
%include Factory.hpp
%include KDMatcher.hpp
%include NifFile.hpp
%include NifUtil.hpp
%include Particles.hpp
%include Skin.hpp

namespace nifly {
  %template(StringExtraDataChildren) NifFile::GetChildren<NiStringExtraData>;

  %template(CreateNamedBSFadeNode) NifFile::CreateNamed<BSFadeNode>;
};

%pragma(csharp) imclasscode=%{
  public static NiObject instantiateConcreteNiObject(System.IntPtr cPtr, bool owner)
  {
      NiObject ret = null;
      if (cPtr == System.IntPtr.Zero) {
          return ret;
      }
      string objType = $modulePINVOKE.NiObject_GetBlockName(new System.Runtime.InteropServices.HandleRef(null, cPtr));
// Code generated by 'pwsh codegen/FactorySnippet.ps1'
if (objType == bhkAabbPhantom.BlockName)
{
    ret = new bhkAabbPhantom(cPtr, owner);
} else if (objType == bhkBallAndSocketConstraint.BlockName)
{
    ret = new bhkBallAndSocketConstraint(cPtr, owner);
} else if (objType == bhkBallSocketConstraintChain.BlockName)
{
    ret = new bhkBallSocketConstraintChain(cPtr, owner);
} else if (objType == bhkBlendCollisionObject.BlockName)
{
    ret = new bhkBlendCollisionObject(cPtr, owner);
} else if (objType == bhkBlendController.BlockName)
{
    ret = new bhkBlendController(cPtr, owner);
} else if (objType == bhkBoxShape.BlockName)
{
    ret = new bhkBoxShape(cPtr, owner);
} else if (objType == bhkBreakableConstraint.BlockName)
{
    ret = new bhkBreakableConstraint(cPtr, owner);
} else if (objType == bhkCapsuleShape.BlockName)
{
    ret = new bhkCapsuleShape(cPtr, owner);
} else if (objType == bhkCollisionObject.BlockName)
{
    ret = new bhkCollisionObject(cPtr, owner);
} else if (objType == bhkCompressedMeshShape.BlockName)
{
    ret = new bhkCompressedMeshShape(cPtr, owner);
} else if (objType == bhkCompressedMeshShapeData.BlockName)
{
    ret = new bhkCompressedMeshShapeData(cPtr, owner);
} else if (objType == bhkConvexListShape.BlockName)
{
    ret = new bhkConvexListShape(cPtr, owner);
} else if (objType == bhkConvexTransformShape.BlockName)
{
    ret = new bhkConvexTransformShape(cPtr, owner);
} else if (objType == bhkConvexVerticesShape.BlockName)
{
    ret = new bhkConvexVerticesShape(cPtr, owner);
} else if (objType == bhkHingeConstraint.BlockName)
{
    ret = new bhkHingeConstraint(cPtr, owner);
} else if (objType == bhkLimitedHingeConstraint.BlockName)
{
    ret = new bhkLimitedHingeConstraint(cPtr, owner);
} else if (objType == bhkLiquidAction.BlockName)
{
    ret = new bhkLiquidAction(cPtr, owner);
} else if (objType == bhkListShape.BlockName)
{
    ret = new bhkListShape(cPtr, owner);
} else if (objType == bhkMalleableConstraint.BlockName)
{
    ret = new bhkMalleableConstraint(cPtr, owner);
} else if (objType == bhkMoppBvTreeShape.BlockName)
{
    ret = new bhkMoppBvTreeShape(cPtr, owner);
} else if (objType == bhkMultiSphereShape.BlockName)
{
    ret = new bhkMultiSphereShape(cPtr, owner);
} else if (objType == bhkNiCollisionObject.BlockName)
{
    ret = new bhkNiCollisionObject(cPtr, owner);
} else if (objType == bhkNiTriStripsShape.BlockName)
{
    ret = new bhkNiTriStripsShape(cPtr, owner);
} else if (objType == bhkNPCollisionObject.BlockName)
{
    ret = new bhkNPCollisionObject(cPtr, owner);
} else if (objType == bhkOrientHingedBodyAction.BlockName)
{
    ret = new bhkOrientHingedBodyAction(cPtr, owner);
} else if (objType == bhkPackedNiTriStripsShape.BlockName)
{
    ret = new bhkPackedNiTriStripsShape(cPtr, owner);
} else if (objType == bhkPCollisionObject.BlockName)
{
    ret = new bhkPCollisionObject(cPtr, owner);
} else if (objType == bhkPhysicsSystem.BlockName)
{
    ret = new bhkPhysicsSystem(cPtr, owner);
} else if (objType == bhkPlaneShape.BlockName)
{
    ret = new bhkPlaneShape(cPtr, owner);
} else if (objType == bhkPoseArray.BlockName)
{
    ret = new bhkPoseArray(cPtr, owner);
} else if (objType == bhkPrismaticConstraint.BlockName)
{
    ret = new bhkPrismaticConstraint(cPtr, owner);
} else if (objType == bhkRagdollConstraint.BlockName)
{
    ret = new bhkRagdollConstraint(cPtr, owner);
} else if (objType == bhkRagdollSystem.BlockName)
{
    ret = new bhkRagdollSystem(cPtr, owner);
} else if (objType == bhkRagdollTemplate.BlockName)
{
    ret = new bhkRagdollTemplate(cPtr, owner);
} else if (objType == bhkRagdollTemplateData.BlockName)
{
    ret = new bhkRagdollTemplateData(cPtr, owner);
} else if (objType == bhkRigidBody.BlockName)
{
    ret = new bhkRigidBody(cPtr, owner);
} else if (objType == bhkRigidBodyT.BlockName)
{
    ret = new bhkRigidBodyT(cPtr, owner);
} else if (objType == bhkSimpleShapePhantom.BlockName)
{
    ret = new bhkSimpleShapePhantom(cPtr, owner);
} else if (objType == bhkSPCollisionObject.BlockName)
{
    ret = new bhkSPCollisionObject(cPtr, owner);
} else if (objType == bhkSphereShape.BlockName)
{
    ret = new bhkSphereShape(cPtr, owner);
} else if (objType == bhkStiffSpringConstraint.BlockName)
{
    ret = new bhkStiffSpringConstraint(cPtr, owner);
} else if (objType == bhkTransformShape.BlockName)
{
    ret = new bhkTransformShape(cPtr, owner);
} else if (objType == BSAnimNote.BlockName)
{
    ret = new BSAnimNote(cPtr, owner);
} else if (objType == BSAnimNotes.BlockName)
{
    ret = new BSAnimNotes(cPtr, owner);
} else if (objType == BSBehaviorGraphExtraData.BlockName)
{
    ret = new BSBehaviorGraphExtraData(cPtr, owner);
} else if (objType == BSBlastNode.BlockName)
{
    ret = new BSBlastNode(cPtr, owner);
} else if (objType == BSBoneLODExtraData.BlockName)
{
    ret = new BSBoneLODExtraData(cPtr, owner);
} else if (objType == BSBound.BlockName)
{
    ret = new BSBound(cPtr, owner);
} else if (objType == BSClothExtraData.BlockName)
{
    ret = new BSClothExtraData(cPtr, owner);
} else if (objType == BSConnectPointChildren.BlockName)
{
    ret = new BSConnectPointChildren(cPtr, owner);
} else if (objType == BSConnectPointParents.BlockName)
{
    ret = new BSConnectPointParents(cPtr, owner);
} else if (objType == BSDamageStage.BlockName)
{
    ret = new BSDamageStage(cPtr, owner);
} else if (objType == BSDebrisNode.BlockName)
{
    ret = new BSDebrisNode(cPtr, owner);
} else if (objType == BSDecalPlacementVectorExtraData.BlockName)
{
    ret = new BSDecalPlacementVectorExtraData(cPtr, owner);
} else if (objType == BSDismemberSkinInstance.BlockName)
{
    ret = new BSDismemberSkinInstance(cPtr, owner);
} else if (objType == BSDistantObjectLargeRefExtraData.BlockName)
{
    ret = new BSDistantObjectLargeRefExtraData(cPtr, owner);
} else if (objType == BSDistantTreeShaderProperty.BlockName)
{
    ret = new BSDistantTreeShaderProperty(cPtr, owner);
} else if (objType == BSDynamicTriShape.BlockName)
{
    ret = new BSDynamicTriShape(cPtr, owner);
} else if (objType == BSEffectShaderProperty.BlockName)
{
    ret = new BSEffectShaderProperty(cPtr, owner);
} else if (objType == BSEffectShaderPropertyColorController.BlockName)
{
    ret = new BSEffectShaderPropertyColorController(cPtr, owner);
} else if (objType == BSEffectShaderPropertyFloatController.BlockName)
{
    ret = new BSEffectShaderPropertyFloatController(cPtr, owner);
} else if (objType == BSEyeCenterExtraData.BlockName)
{
    ret = new BSEyeCenterExtraData(cPtr, owner);
} else if (objType == BSFadeNode.BlockName)
{
    ret = new BSFadeNode(cPtr, owner);
} else if (objType == BSFrustumFOVController.BlockName)
{
    ret = new BSFrustumFOVController(cPtr, owner);
} else if (objType == BSFurnitureMarker.BlockName)
{
    ret = new BSFurnitureMarker(cPtr, owner);
} else if (objType == BSFurnitureMarkerNode.BlockName)
{
    ret = new BSFurnitureMarkerNode(cPtr, owner);
} else if (objType == BSInvMarker.BlockName)
{
    ret = new BSInvMarker(cPtr, owner);
} else if (objType == BSLagBoneController.BlockName)
{
    ret = new BSLagBoneController(cPtr, owner);
} else if (objType == BSLeafAnimNode.BlockName)
{
    ret = new BSLeafAnimNode(cPtr, owner);
} else if (objType == BSLightingShaderProperty.BlockName)
{
    ret = new BSLightingShaderProperty(cPtr, owner);
} else if (objType == BSLightingShaderPropertyColorController.BlockName)
{
    ret = new BSLightingShaderPropertyColorController(cPtr, owner);
} else if (objType == BSLightingShaderPropertyFloatController.BlockName)
{
    ret = new BSLightingShaderPropertyFloatController(cPtr, owner);
} else if (objType == BSLightingShaderPropertyUShortController.BlockName)
{
    ret = new BSLightingShaderPropertyUShortController(cPtr, owner);
} else if (objType == BSLODTriShape.BlockName)
{
    ret = new BSLODTriShape(cPtr, owner);
} else if (objType == BSMasterParticleSystem.BlockName)
{
    ret = new BSMasterParticleSystem(cPtr, owner);
} else if (objType == BSMaterialEmittanceMultController.BlockName)
{
    ret = new BSMaterialEmittanceMultController(cPtr, owner);
} else if (objType == BSMeshLODTriShape.BlockName)
{
    ret = new BSMeshLODTriShape(cPtr, owner);
} else if (objType == BSMultiBound.BlockName)
{
    ret = new BSMultiBound(cPtr, owner);
} else if (objType == BSMultiBoundAABB.BlockName)
{
    ret = new BSMultiBoundAABB(cPtr, owner);
} else if (objType == BSMultiBoundNode.BlockName)
{
    ret = new BSMultiBoundNode(cPtr, owner);
} else if (objType == BSMultiBoundOBB.BlockName)
{
    ret = new BSMultiBoundOBB(cPtr, owner);
} else if (objType == BSMultiBoundSphere.BlockName)
{
    ret = new BSMultiBoundSphere(cPtr, owner);
} else if (objType == BSNiAlphaPropertyTestRefController.BlockName)
{
    ret = new BSNiAlphaPropertyTestRefController(cPtr, owner);
} else if (objType == BSOrderedNode.BlockName)
{
    ret = new BSOrderedNode(cPtr, owner);
} else if (objType == BSPackedAdditionalGeometryData.BlockName)
{
    ret = new BSPackedAdditionalGeometryData(cPtr, owner);
} else if (objType == BSPackedCombinedSharedGeomDataExtra.BlockName)
{
    ret = new BSPackedCombinedSharedGeomDataExtra(cPtr, owner);
} else if (objType == BSParentVelocityModifier.BlockName)
{
    ret = new BSParentVelocityModifier(cPtr, owner);
} else if (objType == BSPositionData.BlockName)
{
    ret = new BSPositionData(cPtr, owner);
} else if (objType == BSProceduralLightningController.BlockName)
{
    ret = new BSProceduralLightningController(cPtr, owner);
} else if (objType == BSPSysArrayEmitter.BlockName)
{
    ret = new BSPSysArrayEmitter(cPtr, owner);
} else if (objType == BSPSysHavokUpdateModifier.BlockName)
{
    ret = new BSPSysHavokUpdateModifier(cPtr, owner);
} else if (objType == BSPSysInheritVelocityModifier.BlockName)
{
    ret = new BSPSysInheritVelocityModifier(cPtr, owner);
} else if (objType == BSPSysLODModifier.BlockName)
{
    ret = new BSPSysLODModifier(cPtr, owner);
} else if (objType == BSPSysMultiTargetEmitterCtlr.BlockName)
{
    ret = new BSPSysMultiTargetEmitterCtlr(cPtr, owner);
} else if (objType == BSPSysRecycleBoundModifier.BlockName)
{
    ret = new BSPSysRecycleBoundModifier(cPtr, owner);
} else if (objType == BSPSysScaleModifier.BlockName)
{
    ret = new BSPSysScaleModifier(cPtr, owner);
} else if (objType == BSPSysSimpleColorModifier.BlockName)
{
    ret = new BSPSysSimpleColorModifier(cPtr, owner);
} else if (objType == BSPSysStripUpdateModifier.BlockName)
{
    ret = new BSPSysStripUpdateModifier(cPtr, owner);
} else if (objType == BSPSysSubTexModifier.BlockName)
{
    ret = new BSPSysSubTexModifier(cPtr, owner);
} else if (objType == BSRangeNode.BlockName)
{
    ret = new BSRangeNode(cPtr, owner);
} else if (objType == BSRefractionFirePeriodController.BlockName)
{
    ret = new BSRefractionFirePeriodController(cPtr, owner);
} else if (objType == BSRefractionStrengthController.BlockName)
{
    ret = new BSRefractionStrengthController(cPtr, owner);
} else if (objType == BSRotAccumTransfInterpolator.BlockName)
{
    ret = new BSRotAccumTransfInterpolator(cPtr, owner);
} else if (objType == BSSegmentedTriShape.BlockName)
{
    ret = new BSSegmentedTriShape(cPtr, owner);
} else if (objType == BSShaderNoLightingProperty.BlockName)
{
    ret = new BSShaderNoLightingProperty(cPtr, owner);
} else if (objType == BSShaderPPLightingProperty.BlockName)
{
    ret = new BSShaderPPLightingProperty(cPtr, owner);
} else if (objType == BSShaderTextureSet.BlockName)
{
    ret = new BSShaderTextureSet(cPtr, owner);
} else if (objType == BSSkinBoneData.BlockName)
{
    ret = new BSSkinBoneData(cPtr, owner);
} else if (objType == BSSkinInstance.BlockName)
{
    ret = new BSSkinInstance(cPtr, owner);
} else if (objType == BSSkyShaderProperty.BlockName)
{
    ret = new BSSkyShaderProperty(cPtr, owner);
} else if (objType == BSStripParticleSystem.BlockName)
{
    ret = new BSStripParticleSystem(cPtr, owner);
} else if (objType == BSStripPSysData.BlockName)
{
    ret = new BSStripPSysData(cPtr, owner);
} else if (objType == BSSubIndexTriShape.BlockName)
{
    ret = new BSSubIndexTriShape(cPtr, owner);
} else if (objType == BSTreadTransfInterpolator.BlockName)
{
    ret = new BSTreadTransfInterpolator(cPtr, owner);
} else if (objType == BSTreeNode.BlockName)
{
    ret = new BSTreeNode(cPtr, owner);
} else if (objType == BSTriShape.BlockName)
{
    ret = new BSTriShape(cPtr, owner);
} else if (objType == BSValueNode.BlockName)
{
    ret = new BSValueNode(cPtr, owner);
} else if (objType == BSWArray.BlockName)
{
    ret = new BSWArray(cPtr, owner);
} else if (objType == BSWaterShaderProperty.BlockName)
{
    ret = new BSWaterShaderProperty(cPtr, owner);
} else if (objType == BSWindModifier.BlockName)
{
    ret = new BSWindModifier(cPtr, owner);
} else if (objType == BSXFlags.BlockName)
{
    ret = new BSXFlags(cPtr, owner);
} else if (objType == DistantLODShaderProperty.BlockName)
{
    ret = new DistantLODShaderProperty(cPtr, owner);
} else if (objType == HairShaderProperty.BlockName)
{
    ret = new HairShaderProperty(cPtr, owner);
} else if (objType == hkPackedNiTriStripsData.BlockName)
{
    ret = new hkPackedNiTriStripsData(cPtr, owner);
} else if (objType == Lighting30ShaderProperty.BlockName)
{
    ret = new Lighting30ShaderProperty(cPtr, owner);
} else if (objType == NiAdditionalGeometryData.BlockName)
{
    ret = new NiAdditionalGeometryData(cPtr, owner);
} else if (objType == NiAlphaController.BlockName)
{
    ret = new NiAlphaController(cPtr, owner);
} else if (objType == NiAlphaProperty.BlockName)
{
    ret = new NiAlphaProperty(cPtr, owner);
} else if (objType == NiAmbientLight.BlockName)
{
    ret = new NiAmbientLight(cPtr, owner);
} else if (objType == NiAutoNormalParticles.BlockName)
{
    ret = new NiAutoNormalParticles(cPtr, owner);
} else if (objType == NiAutoNormalParticlesData.BlockName)
{
    ret = new NiAutoNormalParticlesData(cPtr, owner);
} else if (objType == NiBillboardNode.BlockName)
{
    ret = new NiBillboardNode(cPtr, owner);
} else if (objType == NiBinaryExtraData.BlockName)
{
    ret = new NiBinaryExtraData(cPtr, owner);
} else if (objType == NiBlendBoolInterpolator.BlockName)
{
    ret = new NiBlendBoolInterpolator(cPtr, owner);
} else if (objType == NiBlendFloatInterpolator.BlockName)
{
    ret = new NiBlendFloatInterpolator(cPtr, owner);
} else if (objType == NiBlendPoint3Interpolator.BlockName)
{
    ret = new NiBlendPoint3Interpolator(cPtr, owner);
} else if (objType == NiBlendTransformInterpolator.BlockName)
{
    ret = new NiBlendTransformInterpolator(cPtr, owner);
} else if (objType == NiBone.BlockName)
{
    ret = new NiBone(cPtr, owner);
} else if (objType == NiBoneLODController.BlockName)
{
    ret = new NiBoneLODController(cPtr, owner);
} else if (objType == NiBoolData.BlockName)
{
    ret = new NiBoolData(cPtr, owner);
} else if (objType == NiBooleanExtraData.BlockName)
{
    ret = new NiBooleanExtraData(cPtr, owner);
} else if (objType == NiBoolInterpolator.BlockName)
{
    ret = new NiBoolInterpolator(cPtr, owner);
} else if (objType == NiBoolTimelineInterpolator.BlockName)
{
    ret = new NiBoolTimelineInterpolator(cPtr, owner);
} else if (objType == NiBSBoneLODController.BlockName)
{
    ret = new NiBSBoneLODController(cPtr, owner);
} else if (objType == NiBSplineBasisData.BlockName)
{
    ret = new NiBSplineBasisData(cPtr, owner);
} else if (objType == NiBSplineCompFloatInterpolator.BlockName)
{
    ret = new NiBSplineCompFloatInterpolator(cPtr, owner);
} else if (objType == NiBSplineCompPoint3Interpolator.BlockName)
{
    ret = new NiBSplineCompPoint3Interpolator(cPtr, owner);
} else if (objType == NiBSplineCompTransformInterpolator.BlockName)
{
    ret = new NiBSplineCompTransformInterpolator(cPtr, owner);
} else if (objType == NiBSplineData.BlockName)
{
    ret = new NiBSplineData(cPtr, owner);
} else if (objType == NiBSplineTransformInterpolator.BlockName)
{
    ret = new NiBSplineTransformInterpolator(cPtr, owner);
} else if (objType == NiCamera.BlockName)
{
    ret = new NiCamera(cPtr, owner);
} else if (objType == NiCollisionData.BlockName)
{
    ret = new NiCollisionData(cPtr, owner);
} else if (objType == NiCollisionObject.BlockName)
{
    ret = new NiCollisionObject(cPtr, owner);
} else if (objType == NiColorData.BlockName)
{
    ret = new NiColorData(cPtr, owner);
} else if (objType == NiColorExtraData.BlockName)
{
    ret = new NiColorExtraData(cPtr, owner);
} else if (objType == NiControllerManager.BlockName)
{
    ret = new NiControllerManager(cPtr, owner);
} else if (objType == NiControllerSequence.BlockName)
{
    ret = new NiControllerSequence(cPtr, owner);
} else if (objType == NiDefaultAVObjectPalette.BlockName)
{
    ret = new NiDefaultAVObjectPalette(cPtr, owner);
} else if (objType == NiDirectionalLight.BlockName)
{
    ret = new NiDirectionalLight(cPtr, owner);
} else if (objType == NiDitherProperty.BlockName)
{
    ret = new NiDitherProperty(cPtr, owner);
} else if (objType == NiFlipController.BlockName)
{
    ret = new NiFlipController(cPtr, owner);
} else if (objType == NiFloatData.BlockName)
{
    ret = new NiFloatData(cPtr, owner);
} else if (objType == NiFloatExtraData.BlockName)
{
    ret = new NiFloatExtraData(cPtr, owner);
} else if (objType == NiFloatExtraDataController.BlockName)
{
    ret = new NiFloatExtraDataController(cPtr, owner);
} else if (objType == NiFloatInterpolator.BlockName)
{
    ret = new NiFloatInterpolator(cPtr, owner);
} else if (objType == NiFloatsExtraData.BlockName)
{
    ret = new NiFloatsExtraData(cPtr, owner);
} else if (objType == NiFogProperty.BlockName)
{
    ret = new NiFogProperty(cPtr, owner);
} else if (objType == NiGeomMorpherController.BlockName)
{
    ret = new NiGeomMorpherController(cPtr, owner);
} else if (objType == NiHeader.BlockName)
{
    ret = new NiHeader(cPtr, owner);
} else if (objType == NiIntegerExtraData.BlockName)
{
    ret = new NiIntegerExtraData(cPtr, owner);
} else if (objType == NiIntegersExtraData.BlockName)
{
    ret = new NiIntegersExtraData(cPtr, owner);
} else if (objType == NiKeyframeController.BlockName)
{
    ret = new NiKeyframeController(cPtr, owner);
} else if (objType == NiKeyframeData.BlockName)
{
    ret = new NiKeyframeData(cPtr, owner);
} else if (objType == NiLightColorController.BlockName)
{
    ret = new NiLightColorController(cPtr, owner);
} else if (objType == NiLightDimmerController.BlockName)
{
    ret = new NiLightDimmerController(cPtr, owner);
} else if (objType == NiLightRadiusController.BlockName)
{
    ret = new NiLightRadiusController(cPtr, owner);
} else if (objType == NiLines.BlockName)
{
    ret = new NiLines(cPtr, owner);
} else if (objType == NiLinesData.BlockName)
{
    ret = new NiLinesData(cPtr, owner);
} else if (objType == NiLODNode.BlockName)
{
    ret = new NiLODNode(cPtr, owner);
} else if (objType == NiLookAtController.BlockName)
{
    ret = new NiLookAtController(cPtr, owner);
} else if (objType == NiLookAtInterpolator.BlockName)
{
    ret = new NiLookAtInterpolator(cPtr, owner);
} else if (objType == NiMaterialColorController.BlockName)
{
    ret = new NiMaterialColorController(cPtr, owner);
} else if (objType == NiMaterialProperty.BlockName)
{
    ret = new NiMaterialProperty(cPtr, owner);
} else if (objType == NiMeshParticleSystem.BlockName)
{
    ret = new NiMeshParticleSystem(cPtr, owner);
} else if (objType == NiMeshPSysData.BlockName)
{
    ret = new NiMeshPSysData(cPtr, owner);
} else if (objType == NiMorphData.BlockName)
{
    ret = new NiMorphData(cPtr, owner);
} else if (objType == NiMultiTargetTransformController.BlockName)
{
    ret = new NiMultiTargetTransformController(cPtr, owner);
} else if (objType == NiNode.BlockName)
{
    ret = new NiNode(cPtr, owner);
} else if (objType == NiObject.BlockName)
{
    ret = new NiObject(cPtr, owner);
} else if (objType == NiPalette.BlockName)
{
    ret = new NiPalette(cPtr, owner);
} else if (objType == NiParticleMeshes.BlockName)
{
    ret = new NiParticleMeshes(cPtr, owner);
} else if (objType == NiParticleMeshesData.BlockName)
{
    ret = new NiParticleMeshesData(cPtr, owner);
} else if (objType == NiParticles.BlockName)
{
    ret = new NiParticles(cPtr, owner);
} else if (objType == NiParticlesData.BlockName)
{
    ret = new NiParticlesData(cPtr, owner);
} else if (objType == NiParticleSystem.BlockName)
{
    ret = new NiParticleSystem(cPtr, owner);
} else if (objType == NiPathController.BlockName)
{
    ret = new NiPathController(cPtr, owner);
} else if (objType == NiPathInterpolator.BlockName)
{
    ret = new NiPathInterpolator(cPtr, owner);
} else if (objType == NiPersistentSrcTextureRendererData.BlockName)
{
    ret = new NiPersistentSrcTextureRendererData(cPtr, owner);
} else if (objType == NiPixelData.BlockName)
{
    ret = new NiPixelData(cPtr, owner);
} else if (objType == NiPoint3Interpolator.BlockName)
{
    ret = new NiPoint3Interpolator(cPtr, owner);
} else if (objType == NiPointLight.BlockName)
{
    ret = new NiPointLight(cPtr, owner);
} else if (objType == NiPosData.BlockName)
{
    ret = new NiPosData(cPtr, owner);
} else if (objType == NiPSysAgeDeathModifier.BlockName)
{
    ret = new NiPSysAgeDeathModifier(cPtr, owner);
} else if (objType == NiPSysAirFieldAirFrictionCtlr.BlockName)
{
    ret = new NiPSysAirFieldAirFrictionCtlr(cPtr, owner);
} else if (objType == NiPSysAirFieldInheritVelocityCtlr.BlockName)
{
    ret = new NiPSysAirFieldInheritVelocityCtlr(cPtr, owner);
} else if (objType == NiPSysAirFieldModifier.BlockName)
{
    ret = new NiPSysAirFieldModifier(cPtr, owner);
} else if (objType == NiPSysAirFieldSpreadCtlr.BlockName)
{
    ret = new NiPSysAirFieldSpreadCtlr(cPtr, owner);
} else if (objType == NiPSysBombModifier.BlockName)
{
    ret = new NiPSysBombModifier(cPtr, owner);
} else if (objType == NiPSysBoundUpdateModifier.BlockName)
{
    ret = new NiPSysBoundUpdateModifier(cPtr, owner);
} else if (objType == NiPSysBoxEmitter.BlockName)
{
    ret = new NiPSysBoxEmitter(cPtr, owner);
} else if (objType == NiPSysColliderManager.BlockName)
{
    ret = new NiPSysColliderManager(cPtr, owner);
} else if (objType == NiPSysColorModifier.BlockName)
{
    ret = new NiPSysColorModifier(cPtr, owner);
} else if (objType == NiPSysCylinderEmitter.BlockName)
{
    ret = new NiPSysCylinderEmitter(cPtr, owner);
} else if (objType == NiPSysData.BlockName)
{
    ret = new NiPSysData(cPtr, owner);
} else if (objType == NiPSysDragFieldModifier.BlockName)
{
    ret = new NiPSysDragFieldModifier(cPtr, owner);
} else if (objType == NiPSysDragModifier.BlockName)
{
    ret = new NiPSysDragModifier(cPtr, owner);
} else if (objType == NiPSysEmitterCtlr.BlockName)
{
    ret = new NiPSysEmitterCtlr(cPtr, owner);
} else if (objType == NiPSysEmitterCtlrData.BlockName)
{
    ret = new NiPSysEmitterCtlrData(cPtr, owner);
} else if (objType == NiPSysEmitterDeclinationCtlr.BlockName)
{
    ret = new NiPSysEmitterDeclinationCtlr(cPtr, owner);
} else if (objType == NiPSysEmitterDeclinationVarCtlr.BlockName)
{
    ret = new NiPSysEmitterDeclinationVarCtlr(cPtr, owner);
} else if (objType == NiPSysEmitterInitialRadiusCtlr.BlockName)
{
    ret = new NiPSysEmitterInitialRadiusCtlr(cPtr, owner);
} else if (objType == NiPSysEmitterLifeSpanCtlr.BlockName)
{
    ret = new NiPSysEmitterLifeSpanCtlr(cPtr, owner);
} else if (objType == NiPSysEmitterPlanarAngleCtlr.BlockName)
{
    ret = new NiPSysEmitterPlanarAngleCtlr(cPtr, owner);
} else if (objType == NiPSysEmitterPlanarAngleVarCtlr.BlockName)
{
    ret = new NiPSysEmitterPlanarAngleVarCtlr(cPtr, owner);
} else if (objType == NiPSysEmitterSpeedCtlr.BlockName)
{
    ret = new NiPSysEmitterSpeedCtlr(cPtr, owner);
} else if (objType == NiPSysFieldAttenuationCtlr.BlockName)
{
    ret = new NiPSysFieldAttenuationCtlr(cPtr, owner);
} else if (objType == NiPSysFieldMagnitudeCtlr.BlockName)
{
    ret = new NiPSysFieldMagnitudeCtlr(cPtr, owner);
} else if (objType == NiPSysFieldMaxDistanceCtlr.BlockName)
{
    ret = new NiPSysFieldMaxDistanceCtlr(cPtr, owner);
} else if (objType == NiPSysGravityFieldModifier.BlockName)
{
    ret = new NiPSysGravityFieldModifier(cPtr, owner);
} else if (objType == NiPSysGravityModifier.BlockName)
{
    ret = new NiPSysGravityModifier(cPtr, owner);
} else if (objType == NiPSysGravityStrengthCtlr.BlockName)
{
    ret = new NiPSysGravityStrengthCtlr(cPtr, owner);
} else if (objType == NiPSysGrowFadeModifier.BlockName)
{
    ret = new NiPSysGrowFadeModifier(cPtr, owner);
} else if (objType == NiPSysInitialRotAngleCtlr.BlockName)
{
    ret = new NiPSysInitialRotAngleCtlr(cPtr, owner);
} else if (objType == NiPSysInitialRotAngleVarCtlr.BlockName)
{
    ret = new NiPSysInitialRotAngleVarCtlr(cPtr, owner);
} else if (objType == NiPSysInitialRotSpeedCtlr.BlockName)
{
    ret = new NiPSysInitialRotSpeedCtlr(cPtr, owner);
} else if (objType == NiPSysInitialRotSpeedVarCtlr.BlockName)
{
    ret = new NiPSysInitialRotSpeedVarCtlr(cPtr, owner);
} else if (objType == NiPSysMeshEmitter.BlockName)
{
    ret = new NiPSysMeshEmitter(cPtr, owner);
} else if (objType == NiPSysMeshUpdateModifier.BlockName)
{
    ret = new NiPSysMeshUpdateModifier(cPtr, owner);
} else if (objType == NiPSysModifierActiveCtlr.BlockName)
{
    ret = new NiPSysModifierActiveCtlr(cPtr, owner);
} else if (objType == NiPSysPlanarCollider.BlockName)
{
    ret = new NiPSysPlanarCollider(cPtr, owner);
} else if (objType == NiPSysPositionModifier.BlockName)
{
    ret = new NiPSysPositionModifier(cPtr, owner);
} else if (objType == NiPSysRadialFieldModifier.BlockName)
{
    ret = new NiPSysRadialFieldModifier(cPtr, owner);
} else if (objType == NiPSysResetOnLoopCtlr.BlockName)
{
    ret = new NiPSysResetOnLoopCtlr(cPtr, owner);
} else if (objType == NiPSysRotationModifier.BlockName)
{
    ret = new NiPSysRotationModifier(cPtr, owner);
} else if (objType == NiPSysSpawnModifier.BlockName)
{
    ret = new NiPSysSpawnModifier(cPtr, owner);
} else if (objType == NiPSysSphereEmitter.BlockName)
{
    ret = new NiPSysSphereEmitter(cPtr, owner);
} else if (objType == NiPSysSphericalCollider.BlockName)
{
    ret = new NiPSysSphericalCollider(cPtr, owner);
} else if (objType == NiPSysTurbulenceFieldModifier.BlockName)
{
    ret = new NiPSysTurbulenceFieldModifier(cPtr, owner);
} else if (objType == NiPSysUpdateCtlr.BlockName)
{
    ret = new NiPSysUpdateCtlr(cPtr, owner);
} else if (objType == NiPSysVortexFieldModifier.BlockName)
{
    ret = new NiPSysVortexFieldModifier(cPtr, owner);
} else if (objType == NiRangeLODData.BlockName)
{
    ret = new NiRangeLODData(cPtr, owner);
} else if (objType == NiRollController.BlockName)
{
    ret = new NiRollController(cPtr, owner);
} else if (objType == NiRotatingParticles.BlockName)
{
    ret = new NiRotatingParticles(cPtr, owner);
} else if (objType == NiRotatingParticlesData.BlockName)
{
    ret = new NiRotatingParticlesData(cPtr, owner);
} else if (objType == NiScreenElements.BlockName)
{
    ret = new NiScreenElements(cPtr, owner);
} else if (objType == NiScreenElementsData.BlockName)
{
    ret = new NiScreenElementsData(cPtr, owner);
} else if (objType == NiScreenLODData.BlockName)
{
    ret = new NiScreenLODData(cPtr, owner);
} else if (objType == NiSequence.BlockName)
{
    ret = new NiSequence(cPtr, owner);
} else if (objType == NiSequenceStreamHelper.BlockName)
{
    ret = new NiSequenceStreamHelper(cPtr, owner);
} else if (objType == NiShadeProperty.BlockName)
{
    ret = new NiShadeProperty(cPtr, owner);
} else if (objType == NiSkinData.BlockName)
{
    ret = new NiSkinData(cPtr, owner);
} else if (objType == NiSkinInstance.BlockName)
{
    ret = new NiSkinInstance(cPtr, owner);
} else if (objType == NiSkinPartition.BlockName)
{
    ret = new NiSkinPartition(cPtr, owner);
} else if (objType == NiSortAdjustNode.BlockName)
{
    ret = new NiSortAdjustNode(cPtr, owner);
} else if (objType == NiSourceCubeMap.BlockName)
{
    ret = new NiSourceCubeMap(cPtr, owner);
} else if (objType == NiSourceTexture.BlockName)
{
    ret = new NiSourceTexture(cPtr, owner);
} else if (objType == NiSpecularProperty.BlockName)
{
    ret = new NiSpecularProperty(cPtr, owner);
} else if (objType == NiSpotLight.BlockName)
{
    ret = new NiSpotLight(cPtr, owner);
} else if (objType == NiStencilProperty.BlockName)
{
    ret = new NiStencilProperty(cPtr, owner);
} else if (objType == NiStringExtraData.BlockName)
{
    ret = new NiStringExtraData(cPtr, owner);
} else if (objType == NiStringPalette.BlockName)
{
    ret = new NiStringPalette(cPtr, owner);
} else if (objType == NiStringsExtraData.BlockName)
{
    ret = new NiStringsExtraData(cPtr, owner);
} else if (objType == NiSwitchNode.BlockName)
{
    ret = new NiSwitchNode(cPtr, owner);
} else if (objType == NiTextKeyExtraData.BlockName)
{
    ret = new NiTextKeyExtraData(cPtr, owner);
} else if (objType == NiTextureEffect.BlockName)
{
    ret = new NiTextureEffect(cPtr, owner);
} else if (objType == NiTextureTransformController.BlockName)
{
    ret = new NiTextureTransformController(cPtr, owner);
} else if (objType == NiTexturingProperty.BlockName)
{
    ret = new NiTexturingProperty(cPtr, owner);
} else if (objType == NiTransformController.BlockName)
{
    ret = new NiTransformController(cPtr, owner);
} else if (objType == NiTransformData.BlockName)
{
    ret = new NiTransformData(cPtr, owner);
} else if (objType == NiTransformInterpolator.BlockName)
{
    ret = new NiTransformInterpolator(cPtr, owner);
} else if (objType == NiTriShape.BlockName)
{
    ret = new NiTriShape(cPtr, owner);
} else if (objType == NiTriShapeData.BlockName)
{
    ret = new NiTriShapeData(cPtr, owner);
} else if (objType == NiTriStrips.BlockName)
{
    ret = new NiTriStrips(cPtr, owner);
} else if (objType == NiTriStripsData.BlockName)
{
    ret = new NiTriStripsData(cPtr, owner);
} else if (objType == NiUVController.BlockName)
{
    ret = new NiUVController(cPtr, owner);
} else if (objType == NiUVData.BlockName)
{
    ret = new NiUVData(cPtr, owner);
} else if (objType == NiVectorExtraData.BlockName)
{
    ret = new NiVectorExtraData(cPtr, owner);
} else if (objType == NiVertexColorProperty.BlockName)
{
    ret = new NiVertexColorProperty(cPtr, owner);
} else if (objType == NiVisController.BlockName)
{
    ret = new NiVisController(cPtr, owner);
} else if (objType == NiVisData.BlockName)
{
    ret = new NiVisData(cPtr, owner);
} else if (objType == NiWireframeProperty.BlockName)
{
    ret = new NiWireframeProperty(cPtr, owner);
} else if (objType == NiZBufferProperty.BlockName)
{
    ret = new NiZBufferProperty(cPtr, owner);
} else if (objType == SkyShaderProperty.BlockName)
{
    ret = new SkyShaderProperty(cPtr, owner);
} else if (objType == TallGrassShaderProperty.BlockName)
{
    ret = new TallGrassShaderProperty(cPtr, owner);
} else if (objType == TileShaderProperty.BlockName)
{
    ret = new TileShaderProperty(cPtr, owner);
} else if (objType == VolumetricFogShaderProperty.BlockName)
{
    ret = new VolumetricFogShaderProperty(cPtr, owner);
} else if (objType == WaterShaderProperty.BlockName)
{
    ret = new WaterShaderProperty(cPtr, owner);
} else 
// End Code generated using codegen/FactoryClasses.bat
      {
          System.Diagnostics.Debug.Assert(false,
              System.String.Format("No support for type '{0}' as nifly concrete class", objType));
      }
      return ret;
  }
%}

// helpers for NiStringRef list retrieval
%template(NiVectorBaseNiStringRef) nifly::NiVectorBase<nifly::NiStringRef, uint32_t>;
%template(NiStringRefVectoru32) nifly::NiStringRefVector<uint32_t>;

%template(setNiRef) std::set<nifly::NiRef*>;

%template(arrayVector3_3) std::array<nifly::Vector3, 3>;

%template(NiBlockRefAdditionalGeomData) nifly::NiBlockRef<nifly::AdditionalGeomData>;
%template(NiBlockRefbhkCompressedMeshShapeData) nifly::NiBlockRef<nifly::bhkCompressedMeshShapeData>;
%template(NiBlockRefbhkConvexShape) nifly::NiBlockRef<nifly::bhkConvexShape>;
%template(NiBlockRefbhkEntity) nifly::NiBlockRef<nifly::bhkEntity>;
%template(NiBlockRefbhkRigidBody) nifly::NiBlockRef<nifly::bhkRigidBody>;
%template(NiBlockRefbhkSerializable) nifly::NiBlockRef<nifly::bhkSerializable>;
%template(NiBlockRefbhkShape) nifly::NiBlockRef<nifly::bhkShape>;
%template(NiBlockRefBSAnimNote) nifly::NiBlockRef<nifly::BSAnimNote>;
%template(NiBlockRefBSAnimNotes) nifly::NiBlockRef<nifly::BSAnimNotes>;
%template(NiBlockRefBSMasterParticleSystem) nifly::NiBlockRef<nifly::BSMasterParticleSystem>;
%template(NiBlockRefBSMultiBound) nifly::NiBlockRef<nifly::BSMultiBound>;
%template(NiBlockRefBSMultiBoundData) nifly::NiBlockRef<nifly::BSMultiBoundData>;
%template(NiBlockRefBSShaderProperty) nifly::NiBlockRef<nifly::BSShaderProperty>;
%template(NiBlockRefBSShaderTextureSet) nifly::NiBlockRef<nifly::BSShaderTextureSet>;
%template(NiBlockRefBSSkinBoneData) nifly::NiBlockRef<nifly::BSSkinBoneData>;
%template(NiBlockRefhkPackedNiTriStripsData) nifly::NiBlockRef<nifly::hkPackedNiTriStripsData>;
%template(NiBlockRefNiAlphaProperty) nifly::NiBlockRef<nifly::NiAlphaProperty>;
%template(NiBlockRefNiAVObject) nifly::NiBlockRef<nifly::NiAVObject>;
%template(NiBlockRefNiBoneContainer) nifly::NiBlockRef<nifly::NiBoneContainer>;
%template(NiBlockRefNiBoolData) nifly::NiBlockRef<nifly::NiBoolData>;
%template(NiBlockRefNiBSplineBasisData) nifly::NiBlockRef<nifly::NiBSplineBasisData>;
%template(NiBlockRefNiBSplineData) nifly::NiBlockRef<nifly::NiBSplineData>;
%template(NiBlockRefNiCollisionObject) nifly::NiBlockRef<nifly::NiCollisionObject>;
%template(NiBlockRefNiColorData) nifly::NiBlockRef<nifly::NiColorData>;
%template(NiBlockRefNiControllerManager) nifly::NiBlockRef<nifly::NiControllerManager>;
%template(NiBlockRefNiControllerSequence) nifly::NiBlockRef<nifly::NiControllerSequence>;
%template(NiBlockRefNiDefaultAVObjectPalette) nifly::NiBlockRef<nifly::NiDefaultAVObjectPalette>;
%template(NiBlockRefNiDynamicEffect) nifly::NiBlockRef<nifly::NiDynamicEffect>;
%template(NiBlockRefNiExtraData) nifly::NiBlockRef<nifly::NiExtraData>;
%template(NiBlockRefNiFloatData) nifly::NiBlockRef<nifly::NiFloatData>;
%template(NiBlockRefNiFloatInterpolator) nifly::NiBlockRef<nifly::NiFloatInterpolator>;
%template(NiBlockRefNiGeometryData) nifly::NiBlockRef<nifly::NiGeometryData>;
%template(NiBlockRefNiInterpController) nifly::NiBlockRef<nifly::NiInterpController>;
%template(NiBlockRefNiInterpolator) nifly::NiBlockRef<nifly::NiInterpolator>;
%template(NiBlockRefNiLODData) nifly::NiBlockRef<nifly::NiLODData>;
%template(NiBlockRefNiMorphData) nifly::NiBlockRef<nifly::NiMorphData>;
%template(NiBlockRefNiNode) nifly::NiBlockRef<nifly::NiNode>;
%template(NiBlockRefNiObject) nifly::NiBlockRef<nifly::NiObject>;
%template(NiBlockRefNiObjectNET) nifly::NiBlockRef<nifly::NiObjectNET>;
%template(NiBlockRefNiPalette) nifly::NiBlockRef<nifly::NiPalette>;
%template(NiBlockRefNiParticleSystem) nifly::NiBlockRef<nifly::NiParticleSystem>;
%template(NiBlockRefNiPoint3Interpolator) nifly::NiBlockRef<nifly::NiPoint3Interpolator>;
%template(NiBlockRefNiPosData) nifly::NiBlockRef<nifly::NiPosData>;
%template(NiBlockRefNiProperty) nifly::NiBlockRef<nifly::NiProperty>;
%template(NiBlockRefNiPSysCollider) nifly::NiBlockRef<nifly::NiPSysCollider>;
%template(NiBlockRefNiPSysColliderManager) nifly::NiBlockRef<nifly::NiPSysColliderManager>;
%template(NiBlockRefNiPSysData) nifly::NiBlockRef<nifly::NiPSysData>;
%template(NiBlockRefNiPSysModifier) nifly::NiBlockRef<nifly::NiPSysModifier>;
%template(NiBlockRefNiPSysSpawnModifier) nifly::NiBlockRef<nifly::NiPSysSpawnModifier>;
%template(NiBlockRefNiShader) nifly::NiBlockRef<nifly::NiShader>;
%template(NiBlockRefNiSkinData) nifly::NiBlockRef<nifly::NiSkinData>;
%template(NiBlockRefNiSkinPartition) nifly::NiBlockRef<nifly::NiSkinPartition>;
%template(NiBlockRefNiSourceTexture) nifly::NiBlockRef<nifly::NiSourceTexture>;
%template(NiBlockRefNiTextKeyExtraData) nifly::NiBlockRef<nifly::NiTextKeyExtraData>;
%template(NiBlockRefNiTimeController) nifly::NiBlockRef<nifly::NiTimeController>;
%template(NiBlockRefNiTransformData) nifly::NiBlockRef<nifly::NiTransformData>;
%template(NiBlockRefNiUVData) nifly::NiBlockRef<nifly::NiUVData>;
%template(NiBlockRefNiTriStripsData) nifly::NiBlockRef<nifly::NiTriStripsData>;
%template(NiBlockRefTextureRenderData) nifly::NiBlockRef<nifly::TextureRenderData>;

%template(NiVectorBasehalf) nifly::NiVectorBase<half_float::half, uint32_t>;
%template(NiVectorhalf) nifly::NiVector<half_float::half, uint32_t>;
%template(NiVectorBasefloat) nifly::NiVectorBase<float, uint32_t>;
%template(NiVectorfloat) nifly::NiVector<float, uint32_t>;
%template(NiVectorBaseint) nifly::NiVectorBase<int, uint32_t>;
%template(NiVectorint) nifly::NiVector<int, uint32_t>;
%template(NiVectorBaseshort) nifly::NiVectorBase<short, uint32_t>;
%template(NiVectorshort) nifly::NiVector<short, uint32_t>;
%template(NiVectorBaseuint) nifly::NiVectorBase<unsigned int, uint32_t>;
%template(NiVectoruint) nifly::NiVector<unsigned int, uint32_t>;
%template(NiVectorBaseuchar) nifly::NiVectorBase<unsigned char, uint32_t>;
%template(NiVectoruchar) nifly::NiVector<unsigned char, uint32_t>;
%template(NiVectorBaseushort) nifly::NiVectorBase<unsigned short, uint32_t>;
%template(NiVectorushort) nifly::NiVector<unsigned short, uint32_t>;
%template(NiVectorBaseushortushort) nifly::NiVectorBase<unsigned short, unsigned short>;
%template(NiVectorushortushort) nifly::NiVector<unsigned short, unsigned short>;
%template(NiVectorBasebhkCMSDMaterial) nifly::NiVectorBase<bhkCMSDMaterial, uint32_t>;
%template(NiVectorbhkCMSDMaterial) nifly::NiVector<bhkCMSDMaterial, uint32_t>;
%template(NiVectorBasebhkCMSDTransform) nifly::NiVectorBase<bhkCMSDTransform, uint32_t>;
%template(NiVectorbhkCMSDTransform) nifly::NiVector<bhkCMSDTransform, uint32_t>;
%template(NiVectorBaseBoneMatrix) nifly::NiVectorBase<BoneMatrix, uint32_t>;
%template(NiVectorBoneMatrix) nifly::NiVector<BoneMatrix, uint32_t>;
%template(NiVectorBaseBoundingSphere) nifly::NiVectorBase<BoundingSphere, uint32_t>;
%template(NiVectorBoundingSphere) nifly::NiVector<BoundingSphere, uint32_t>;
%template(NiVectorBaseBSPackedGeomDataCombined) nifly::NiVectorBase<BSPackedGeomDataCombined, uint32_t>;
%template(NiVectorBSPackedGeomDataCombined) nifly::NiVector<BSPackedGeomDataCombined, uint32_t>;
%template(NiVectorBaseByteColor4) nifly::NiVectorBase<ByteColor4, uint32_t>;
%template(NiVectorByteColor4) nifly::NiVector<ByteColor4, uint32_t>;
%template(NiVectorBaseHavokFilter) nifly::NiVectorBase<HavokFilter, uint32_t>;
%template(NiVectorHavokFilter) nifly::NiVector<HavokFilter, uint32_t>;
%template(NiVectorBasehkSubPartData) nifly::NiVectorBase<hkSubPartData, unsigned short>;
%template(NiVectorhkSubPartData) nifly::NiVector<hkSubPartData, unsigned short>;
%template(NiVectorBaseLODRange) nifly::NiVectorBase<LODRange, uint32_t>;
%template(NiVectorLODRange) nifly::NiVector<LODRange, uint32_t>;
%template(NiVectorBaseNiString) nifly::NiVectorBase<NiString, uint32_t>;
%template(NiStringVector) nifly::NiStringVector<uint32_t, 4>;
%template(NiVectorBaseVector3) nifly::NiVectorBase<Vector3, uint32_t>;
%template(NiVectorVector3) nifly::NiVector<Vector3, uint32_t>;
%template(NiVectorBaseVector4) nifly::NiVectorBase<Vector4, uint32_t>;
%template(NiVectorVector4) nifly::NiVector<Vector4, uint32_t>;

%template(vectorNiBlockRefbhkConvexShape) std::vector<nifly::NiBlockRef<nifly::bhkConvexShape>>;
%template(vectorNiBlockRefbhkEntity) std::vector<nifly::NiBlockRef<nifly::bhkEntity>>;
%template(vectorNiBlockRefbhkSerializable) std::vector<nifly::NiBlockRef<nifly::bhkSerializable>>;
%template(vectorNiBlockRefbhkShape) std::vector<nifly::NiBlockRef<nifly::bhkShape>>;
%template(vectorNiBlockRefNiAVObject) std::vector<nifly::NiBlockRef<nifly::NiAVObject>>;
%template(vectorNiBlockRefBSAnimNote) std::vector<nifly::NiBlockRef<nifly::BSAnimNote>>;
%template(vectorNiBlockRefBSAnimNotes) std::vector<nifly::NiBlockRef<nifly::BSAnimNotes>>;
%template(vectorNiBlockRefNiControllerSequence) std::vector<nifly::NiBlockRef<nifly::NiControllerSequence>>;
%template(vectorNiBlockRefNiDynamicEffect) std::vector<nifly::NiBlockRef<nifly::NiDynamicEffect>>;
%template(vectorNiBlockRefNiExtraData) std::vector<nifly::NiBlockRef<nifly::NiExtraData>>;
%template(vectorNiBlockRefNiNode) std::vector<nifly::NiBlockRef<nifly::NiNode>>;
%template(vectorNiBlockRefNiObject) std::vector<nifly::NiBlockRef<nifly::NiObject>>;
%template(vectorNiBlockRefNiProperty) std::vector<nifly::NiBlockRef<nifly::NiProperty>>;
%template(vectorNiBlockRefNiPSysModifier) std::vector<nifly::NiBlockRef<nifly::NiPSysModifier>>;
%template(vectorNiBlockRefNiSourceTexture) std::vector<nifly::NiBlockRef<nifly::NiSourceTexture>>;
%template(vectorNiBlockRefNiTriStripsData) std::vector<nifly::NiBlockRef<nifly::NiTriStripsData>>;

%template(NiBlockRefArraybhkConvexShape) nifly::NiBlockRefArray<nifly::bhkConvexShape>;
%template(NiBlockRefArraybhkEntity) nifly::NiBlockRefArray<nifly::bhkEntity>;
%template(NiBlockRefArraybhkSerializable) nifly::NiBlockRefArray<nifly::bhkSerializable>;
%template(NiBlockRefArraybhkRigidBody) nifly::NiBlockRefArray<nifly::bhkRigidBody>;
%template(NiBlockRefArraybhkShape) nifly::NiBlockRefArray<nifly::bhkShape>;
%template(NiBlockRefArrayBSAnimNote) nifly::NiBlockRefArray<nifly::BSAnimNote>;
%template(NiBlockRefArrayBSAnimNotes) nifly::NiBlockRefArray<nifly::BSAnimNotes>;
%template(NiBlockRefArrayBSMasterParticleSystem) nifly::NiBlockRefArray<nifly::BSMasterParticleSystem>;
%template(NiBlockRefArrayNiAVObject) nifly::NiBlockRefArray<nifly::NiAVObject>;
%template(NiBlockRefArrayNiControllerManager) nifly::NiBlockRefArray<nifly::NiControllerManager>;
%template(NiBlockRefArrayNiControllerSequence) nifly::NiBlockRefArray<nifly::NiControllerSequence>;
%template(NiBlockRefArrayNiDynamicEffect) nifly::NiBlockRefArray<nifly::NiDynamicEffect>;
%template(NiBlockRefArrayNiExtraData) nifly::NiBlockRefArray<nifly::NiExtraData>;
%template(NiBlockRefArrayNiNode) nifly::NiBlockRefArray<nifly::NiNode>;
%template(NiBlockRefArrayNiObject) nifly::NiBlockRefArray<nifly::NiObject>;
%template(NiBlockRefArrayNiObjectNET) nifly::NiBlockRefArray<nifly::NiObjectNET>;
%template(NiBlockRefArrayNiParticleSystem) nifly::NiBlockRefArray<nifly::NiParticleSystem>;
%template(NiBlockRefArrayNiProperty) nifly::NiBlockRefArray<nifly::NiProperty>;
%template(NiBlockRefArrayNiPSysModifier) nifly::NiBlockRefArray<nifly::NiPSysModifier>;
%template(NiBlockRefArrayNiPSysColliderManager) nifly::NiBlockRefArray<nifly::NiPSysColliderManager>;
%template(NiBlockRefArrayNiSourceTexture) nifly::NiBlockRefArray<nifly::NiSourceTexture>;
%template(NiBlockRefArrayNiTriStripsData) nifly::NiBlockRefArray<nifly::NiTriStripsData>;

%template(NiBlockRefShortArrayBSAnimNote) nifly::NiBlockRefShortArray<nifly::BSAnimNote>;
%template(NiBlockRefShortArrayBSAnimNotes) nifly::NiBlockRefShortArray<nifly::BSAnimNotes>;

%template() nifly::NiBlockPtr<nifly::bhkEntity>;
%template() nifly::NiBlockPtr<nifly::BSMasterParticleSystem>;
%template() nifly::NiBlockPtr<nifly::NiAVObject>;
%template() nifly::NiBlockPtr<nifly::NiControllerManager>;
%template() nifly::NiBlockPtr<nifly::NiNode>;
%template() nifly::NiBlockPtr<nifly::NiObject>;
%template() nifly::NiBlockPtr<nifly::NiObjectNET>;
%template() nifly::NiBlockPtr<nifly::NiParticleSystem>;
%template() nifly::NiBlockPtr<nifly::NiPSysColliderManager>;

%template() nifly::NiBlockPtrArray<nifly::bhkEntity>;
%template() nifly::NiBlockPtrArray<nifly::bhkRigidBody>;
%template() nifly::NiBlockPtrArray<nifly::NiAVObject>;
%template() nifly::NiBlockPtrArray<nifly::NiNode>;

%template() nifly::NiBlockPtrShortArray<nifly::NiAVObject>;

%template(vectorNiBlockPtrArrayNiNode) std::vector<nifly::NiBlockPtrArray<nifly::NiNode>>;

%template(vectorhalf) std::vector<half_float::half>;

%template(vectorAdditionalDataBlock) std::vector<nifly::AdditionalDataBlock>;
%template(vectorAdditionalDataInfo) std::vector<nifly::AdditionalDataInfo>;
%template(vectorAVObject) std::vector<nifly::AVObject>;
%template(vectorbhkCMSDBigTris) std::vector<nifly::bhkCMSDBigTris>;
%template(vectorbhkCMSDChunk) std::vector<nifly::bhkCMSDChunk>;
%template(vectorbhkCMSDMaterial) std::vector<bhkCMSDMaterial>;
%template(vectorbhkCMSDTransform) std::vector<bhkCMSDTransform>;
%template(vectorBoneLOD) std::vector<nifly::BoneLOD>;
%template(vectorBoneMatrix) std::vector<BoneMatrix>;
%template(vectorBonePose) std::vector<nifly::BonePose>;
%template(vectorBoneIndices) std::vector<nifly::BoneIndices>;
%template(vectorBoundingSphere) std::vector<BoundingSphere>;
%template(vectorBoundingVolume) std::vector<nifly::BoundingVolume>;
%template(vectorBSConnectPoint) std::vector<nifly::BSConnectPoint>;
%template(vectorBSGeometrySegmentData) std::vector<nifly::BSGeometrySegmentData>;
%template(vectorBSPackedAdditionalDataBlock) std::vector<nifly::BSPackedAdditionalDataBlock>;
%template(vectorBSPackedGeomData) std::vector<nifly::BSPackedGeomData>;
%template(vectorBSPackedGeomDataCombined) std::vector<BSPackedGeomDataCombined>;
%template(vectorBSPackedGeomObject) std::vector<nifly::BSPackedGeomObject>;
%template(vectorBSSkinBoneDataBoneData) std::vector<nifly::BSSkinBoneData::BoneData>;
%template(vectorBSSITSSegment) std::vector<nifly::BSSubIndexTriShape::BSSITSSegment>;
%template(vectorBSSITSSubSegment) std::vector<nifly::BSSubIndexTriShape::BSSITSSubSegment>;
%template(vectorBSSITSSubSegmentDataRecord) std::vector<nifly::BSSubIndexTriShape::BSSITSSubSegmentDataRecord>;
%template(vectorBSTextureArray) std::vector<nifly::BSTextureArray>;
%template(vectorBSTreadTransform) std::vector<nifly::BSTreadTransform>;
%template(vectorBSVertexData) std::vector<nifly::BSVertexData>;
%template(vectorByteColor4) std::vector<ByteColor4>;
%template(vectorColor4) std::vector<nifly::Color4>;
%template(vectorConstraintData) std::vector<nifly::ConstraintData>;
%template(vectorControllerLink) std::vector<nifly::ControllerLink>;
%template(vectorDecalVectorBlock) std::vector<nifly::DecalVectorBlock>;
%template(vectorFurniturePosition) std::vector<nifly::FurniturePosition>;
%template(vectorHavokFilter) std::vector<HavokFilter>;
%template(vectorhkSubPartData) std::vector<hkSubPartData>;
%template(vectorhkTriangleData) std::vector<nifly::hkTriangleData>;
%template(vectorhkTriangleNormalData) std::vector<nifly::hkTriangleNormalData>;
%template(vectorInterpBlendItem) std::vector<nifly::InterpBlendItem>;
%template(vectorkd_query_result) std::vector<nifly::kd_query_result>;
%template(vectorKeyNiStringRef) std::vector<nifly::Key<nifly::NiStringRef>>;
%template(vectorKeyQuaternion) std::vector<nifly::Key<nifly::Quaternion>>;
%template(vectorKeyuchar) std::vector<nifly::Key<unsigned char>>;
%template(vectorLODRange) std::vector<LODRange>;
%template(vectorMatchGroup) std::vector<nifly::MatchGroup>;
%template(vectorMaterialInfo) std::vector<nifly::MaterialInfo>;
%template(vectorMatrix3) std::vector<nifly::Matrix3>;
%template(vectorMatTransform) std::vector<nifly::MatTransform>;
%template(vectorMipMapInfo) std::vector<nifly::MipMapInfo>;
%template(vectorMorph) std::vector<nifly::Morph>;
%template(vectorMorphWeight) std::vector<nifly::MorphWeight>;
%template(vectorNifSegmentInfo) std::vector<nifly::NifSegmentInfo>;
%template(vectorNifSubSegmentInfo) std::vector<nifly::NifSubSegmentInfo>;
%template(vectorNiNode) std::vector<nifly::NiNode*>;
%template(vectorNiObject) std::vector<nifly::NiObject*>;
%template(vectorNiShape) std::vector<nifly::NiShape*>;
%template(vectorNiSkinDataBoneData) std::vector<nifly::NiSkinData::BoneData>;
%template(vectorNiString) std::vector<nifly::NiString>;
%template(vectorNiStringExtraData)  std::vector<nifly::NiStringExtraData*>;
%template(vectorNiStringRef) std::vector<nifly::NiStringRef>;
%template(vectorNiStringRefPtr) std::vector<nifly::NiStringRef*>;
%template(vectorPartitionBlock) std::vector<nifly::NiSkinPartition::PartitionBlock>;
%template(vectorPartitionInfo) std::vector<nifly::BSDismemberSkinInstance::PartitionInfo>;
%template(vectorShaderTexDesc) std::vector<nifly::ShaderTexDesc>;
%template(vectorSkinWeight) std::vector<nifly::SkinWeight>;
%template(vectorTriangle) std::vector<nifly::Triangle>;
%template(vector2DVector2) std::vector<std::vector<nifly::Vector2>>;
%template(vectorVector2) std::vector<nifly::Vector2>;
%template(vectorVector3) std::vector<nifly::Vector3>;
%template(vectorVector4) std::vector<nifly::Vector4>;
%template(vectorVertexWeight) std::vector<nifly::VertexWeight>;

%template(Keyfloat) nifly::Key<float>;
%template(KeyColor4) nifly::Key<Color4>;
%template(KeyVector3) nifly::Key<nifly::Vector3>;
%template(Keyuchar) nifly::Key<unsigned char>;
%template(KeyNiStringRef) nifly::Key<nifly::NiStringRef>;
%template(KeyQuaternion) nifly::Key<nifly::Quaternion>;

%template(KeyGroupfloat) nifly::KeyGroup<float>;
%template(KeyGroupColor4) nifly::KeyGroup<nifly::Color4>;
%template(KeyGroupVector3) nifly::KeyGroup<nifly::Vector3>;
%template(KeyGroupuchar) nifly::KeyGroup<unsigned char>;
%template(KeyGroupNiStringRef) nifly::KeyGroup<nifly::NiStringRef>;
