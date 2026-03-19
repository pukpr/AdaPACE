#include <gz/sim/System.hh>
#include <gz/sim/components/Name.hh>
#include <gz/sim/components/Pose.hh>
#include <gz/sim/components/AngularVelocity.hh>
#include <gz/sim/components/JointForceCmd.hh>
#include <gz/sim/components/JointPosition.hh>
#include <gz/sim/Link.hh>
#include <gz/sim/Joint.hh>
#include <gz/plugin/Register.hh>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <map>
#include "shared_structs.h"

using namespace gz;
using namespace sim;

namespace custom_sim {

class TableControlPlugin : public System, public ISystemPostUpdate {
private:
    SharedWorldTable* shm_ptr = nullptr;
    std::map<std::string, uint64_t> last_sequences;

public:
    TableControlPlugin() {
        // Locate the segment (do not use IPC_CREAT here, assume producer did it)
        int shmid = shmget(SHM_KEY, sizeof(SharedWorldTable), 0666);
        if (shmid != -1) {
            shm_ptr = (SharedWorldTable*)shmat(shmid, NULL, 0);
        }
    }

    void PostUpdate(const UpdateInfo &_info, const EntityComponentManager &_ecm) override {
        if (!shm_ptr || shm_ptr == (void*)-1) return;

        auto &mutableEcm = const_cast<EntityComponentManager &>(_ecm);

        for (uint32_t i = 0; i < shm_ptr->active_entities; ++i) {
            EntityState& entry = shm_ptr->entities[i];
            std::string name(entry.name);

            if (entry.sequence > last_sequences[name]) {
                Entity entity = _ecm.EntityByComponents(components::Name(name));
                if (entity != kNullEntity) {
                  
                  // Check if it's a joint
                  bool is_joint = _ecm.Component<components::JointPosition>(entity) != nullptr ||
                                  _ecm.Component<components::JointForceCmd>(entity) != nullptr;

                  // If not identified as joint yet, try to see if it has joint components
                  // or if we can wrap it as a Joint object
                  gz::sim::Joint joint_obj(entity);
                  
                  switch (entry.command) {
                    case 0:{ // SET_POSE / SET_POSITION
                      auto posComp = mutableEcm.Component<components::JointPosition>(entity);
                      if (posComp) {
                          posComp->Data()[0] = entry.roll;
                      } else {
                          auto poseComp = mutableEcm.Component<components::Pose>(entity);
                          if (poseComp) {
                              poseComp->Data() = math::Pose3d(entry.x, entry.y, entry.z, 
                                                             entry.roll, entry.pitch, entry.yaw);
                              mutableEcm.SetChanged(entity, components::Pose::typeId, ComponentState::OneTimeChange);
                          }
                      }
                      last_sequences[name] = entry.sequence;
                      break;
                    }
                    case 1:{ // SET_ROT / SET_VELOCITY
                      auto link = gz::sim::Link(entity);
                      if (link.Valid(_ecm)) {
                          link.SetAngularVelocity(mutableEcm, math::Vector3d(entry.roll, entry.pitch, entry.yaw));
                      }
                      last_sequences[name] = entry.sequence;
                      break;
                    }
                    case 2:{ // SET_TORQUE / SET_FORCE
                      auto forceComp = mutableEcm.Component<components::JointForceCmd>(entity);
                      if (forceComp) {
                          forceComp->Data()[0] = entry.roll;
                      } else {
                          auto link = gz::sim::Link(entity);
                          if (link.Valid(_ecm)) {
                              link.AddWorldWrench(mutableEcm, math::Vector3d(0.0, 0.0, 0.0),
                                                              math::Vector3d(entry.roll, entry.pitch, entry.yaw),
                                                              math::Vector3d(entry.x, entry.y, entry.z));
                          }
                      }
                      last_sequences[name] = entry.sequence;
                      break;
                    }
                    default:
                     break;
                  }
                }
            }
        }
    }
};

GZ_ADD_PLUGIN(TableControlPlugin, System, TableControlPlugin::ISystemPostUpdate)
}
