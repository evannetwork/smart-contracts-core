pragma solidity ^0.4.24;

import "./BaseContractZero.sol";
import "./BaseContractZeroInterface.sol";
import "./BusinessCenterInterface.sol";
import "./EventHubBusinessCenter.sol";
import "./EnsReader.sol";
import "./DSRolesPerContract.sol";


library BaseContractZeroLibrary {
    event StateshiftEvent(uint state, address indexed partner);
    
    uint8 private constant MEMBER_ROLE = 1;
    // // web3.utils.soliditySha3('contacts')
    // bytes32 private constant CONTACTS_LABEL = 0x8417ef2e3e7bb6630d90a4cdcc188db4bcc27d6b2d8891b376ef771499bb4299;
    // web3.utils.soliditySha3('eventhub')
    bytes32 private constant EVENTHUB_LABEL = 0xea14ea6d138254c1a2931c6a19f6888c7b52f512d165cfa428183a53dd9dfb8c;
    // // web3.utils.soliditySha3('profile')
    // bytes32 private constant PROFILE_LABEL = 0xe3dd854eb9d23c94680b3ec632b9072842365d9a702ab0df7da8bc398ee52c7d;

    struct Data {
        BaseContractZeroInterface.ContractState contractState;
        bytes32 contractType;
        uint created;
        uint consumerCount;
        mapping(uint=>address) index2consumer;
        mapping(address=>uint) consumer2index;
        mapping (address => BaseContractZeroInterface.ConsumerState) consumerState;
        bool allowConsumerInvite;
    }
    

    function changeConsumerState(Data storage data, address consumer, BaseContractZeroInterface.ConsumerState state) public {
        BaseContractZeroInterface.ConsumerState currentState = data.consumerState[consumer];
        if (msg.sender == consumer) {
            if (currentState == BaseContractZeroInterface.ConsumerState.Initial && state == BaseContractZeroInterface.ConsumerState.Draft ||
                    currentState == BaseContractZeroInterface.ConsumerState.Draft && state == BaseContractZeroInterface.ConsumerState.Active ||
                    currentState == BaseContractZeroInterface.ConsumerState.Draft && state == BaseContractZeroInterface.ConsumerState.Rejected ||
                    state == BaseContractZeroInterface.ConsumerState.Terminated) {
                data.consumerState[msg.sender] = state;
                emit StateshiftEvent(uint(state), msg.sender);
            } else {
                assert(false);
            }
        } else {
            assert(BaseContractZeroInterface(this).isConsumer(consumer));
            if (currentState == BaseContractZeroInterface.ConsumerState.Initial && state == BaseContractZeroInterface.ConsumerState.Draft ||
                    state == BaseContractZeroInterface.ConsumerState.Terminated) {
                data.consumerState[consumer] = state;
                emit StateshiftEvent(uint(state), consumer);
            } else {
                assert(false);
            }
        }
    }

    function inviteConsumer(Data storage data, address consumer, address businessCenter) public {
        BaseContractZero self = BaseContractZero(this);
        address owner = self.owner();

        // throw if not owner and not allowConsumerInvite
        assert(msg.sender == owner || data.allowConsumerInvite);

        // throw if not owner and not member
        assert(msg.sender == owner || self.isConsumer(msg.sender));

        // thow if member and allowConsumerInvite disabled
        assert(msg.sender == owner || !self.isConsumer(msg.sender) || data.allowConsumerInvite);

        // --> disabled for now // throw if invitee doesn't know contact / blocks this user
        // ProfileIndexInterface pIndex = ProfileIndexInterface(getAddr(PROFILE_LABEL));
        // DataContractInterface profile = DataContractInterface(pIndex.getProfile(consumer));
        // if last bit is set, then invitee has set its known flag for msg.sender to true
        // assert((profile.getMappingValue(CONTACTS_LABEL, keccak256(msg.sender)) & 1) == 1);

        if (businessCenter != 0x0) {
            BusinessCenterInterface businessCenterInterface = BusinessCenterInterface(businessCenter);
            assert(businessCenterInterface.isMember(consumer));
            assert(!self.isConsumer(consumer));
            businessCenterInterface.registerContractMember(this, consumer, data.contractType);
        } else {
            // trigger event from here if not attached to business businessCenter
            // TODO: stick to EnsReader or use self (as it was done in original implementation)
            EventHubBusinessCenter eventHub = EventHubBusinessCenter(self.getAddr(EVENTHUB_LABEL));
            eventHub.sendContractEvent(
                uint(EventHubBusinessCenter.BusinessCenterEventType.New), data.contractType, this, consumer);
        }
        uint id = ++data.consumerCount;
        data.consumer2index[consumer] = id;
        data.index2consumer[id] = consumer;
        data.consumerState[consumer] = BaseContractZeroInterface.ConsumerState.Draft;

        // update permissions
        DSRolesPerContract roles = DSRolesPerContract(self.authority());
        roles.setUserRole(consumer, MEMBER_ROLE, true);
        emit StateshiftEvent(uint(BaseContractZeroInterface.ConsumerState.Draft), consumer);
    }

    function removeConsumer(Data storage data, address consumer, address businessCenter) public {
        BaseContractZero self = BaseContractZero(this);
        assert(self.isConsumer(consumer));

        uint lastId = data.consumerCount--;
        uint idToOverwrite = data.consumer2index[consumer];

        data.index2consumer[idToOverwrite] = data.index2consumer[lastId];
        delete data.index2consumer[lastId];

        data.consumer2index[data.index2consumer[idToOverwrite]] = idToOverwrite;
        delete data.consumer2index[consumer];

        delete data.consumerState[consumer];

        DSRolesPerContract roles = DSRolesPerContract(self.authority());
        roles.setUserRole(consumer, MEMBER_ROLE, false);

        if (businessCenter != 0x0) {
            BusinessCenterInterface businessCenterInterface = BusinessCenterInterface(businessCenter);
            assert(businessCenterInterface.isMember(consumer));
            assert(!self.isConsumer(consumer));
            businessCenterInterface.removeContractMember(this, consumer, data.contractType);
        } else {
            // trigger event from here if not attached to business businessCenter
            EventHubBusinessCenter eventHub = EventHubBusinessCenter(self.getAddr(EVENTHUB_LABEL));
            eventHub.sendContractEvent(
                uint(EventHubBusinessCenter.BusinessCenterEventType.Cancel), data.contractType, this, consumer);
        }
    }
}