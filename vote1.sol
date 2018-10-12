/**
 * 问题：设计并实现一个合约，功能是简单的投票系统，
 * 可以发布投票，所有人都可以参与投票；在发布者结束投票时，
 * 当系统内超过3/2的人参与投票且1/2以上的投了赞成票，
 * 则投票确认，否则投票否决。
 *
 * 解题提示：可以保存当前的参与系统的用户账户；
 * 保存投票内容等；投票内容涉及发布者等信息。
 */
pragma solidity ^ 0.4 .24;


contract Vote {
    // 状态码
    uint CODE_SUCCESS = 2000; // 操作成功
    // uint CODE_VOTE_AGREE = 2010; // 支持状态 - 仅投票结束返回
    uint CODE_VOTE_REJECT = 2011; // 否决状态 - 仅投票结束返回
    uint CODE_ERR_ISVOTED = 3001; // 已经投票过
    uint CODE_ERR_PERMISSION = 3002; // 权限不足
    // uint CODE_ERR_NOTFOUNDVOTETOPIC = 3003; // 未找到投票主题
    // uint CODE_ERR_VOTETOPICISEXIST = 3004; // 当前投票主题已存在
    // uint CODE_ERR_INVALIDOPERATION = 3005; // 针对投票 - 无效操作
    uint CODE_ERR_VOTEISSTART = 3005; // 投票已开启
    uint CODE_ERR_VOTEISEND = 3006; // 投票已结束
    uint CODE_ERR_VOTEISGREETER = 3007; // 投票选项过多

    address initiator; // 发起人

    bool status; // 投票状态 true:标识开启 | false:标识结束

    // 投票内容
    struct VoteType {
        bytes32 voteTopic; // 投票主题
        uint agreeCount; // 赞成票
        uint opposeCount; // 否决票
    }
    VoteType[] voteTypes; // 所有投票

    struct Voter {
        bool voteOpt; // 投票选项 true:标识赞成 | false:标识反对
        bool voted; // 若为真，代表该人已投票
    }
    mapping(address => Voter) voters; // 投票人地址 => 投票人

    // 构造函数 初始化投票
    constructor() public {
        initiator = msg.sender;
        status = false;
    }

    /**
     * 投票方法
     */
    function vote(uint voteIndex, bool votvoteOption) public returns(uint) {
        if (!status) {
            return CODE_ERR_VOTEISEND;
        }
        Voter storage sender = voters[msg.sender];
        if (sender.voted) {
            // 已经投票过
            return CODE_ERR_ISVOTED;
        }
        sender.voted = true;
        sender.voteOpt = votvoteOption;
        if (votvoteOption) {
            voteTypes[voteIndex].agreeCount++;
        } else {
            voteTypes[voteIndex].opposeCount++;
        }

        return CODE_SUCCESS;
    }

    /**
     * 开始投票
     */
    function startVote(bytes32[] voteTopicTitles) public returns(uint) {
        if (status) {
            return CODE_ERR_VOTEISSTART;
        }
        if (msg.sender != initiator) {
            return CODE_ERR_PERMISSION;
        }
        if (voteTopicTitles.length > 2000) {
            return CODE_ERR_VOTEISGREETER;
        }
        status = true;
        for (uint i = 0; i < voteTopicTitles.length; i++) {
            voteTypes.push(VoteType({
                voteTopic: voteTopicTitles[i],
                agreeCount: 0,
                opposeCount: 0
            }));
        }
        return CODE_SUCCESS;
    }

    /**
     * 结束投票 (返回投票确认项Index, 没有胜出的投票项就返回投票否决)
     */
    function endVote() public returns(uint) {
        if (!status) {
            return CODE_ERR_VOTEISEND;
        }
        if (msg.sender != initiator) {
            return CODE_ERR_PERMISSION;
        }
        status = false;

        uint allCount = 0; // 总人数
        uint voteTypesLength = voteTypes.length;
        uint i;
        for (i = 0; i < voteTypesLength; i++) {
            allCount += voteTypes[i].agreeCount;
            allCount += voteTypes[i].opposeCount;
        }

        for (i = 0; i < voteTypesLength; i++) {
            VoteType storage currentVote = voteTypes[i];
            if ((currentVote.agreeCount + currentVote.opposeCount)*3 > 2*allCount ) {
                if (currentVote.agreeCount > currentVote.opposeCount) {
                    return i;
                }
            }
        }
        return CODE_VOTE_REJECT;
    }
}