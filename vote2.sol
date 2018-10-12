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
    uint CODE_VOTE_AGREE = 2010; // 支持状态 - 仅投票结束返回
    uint CODE_VOTE_REJECT = 2011; // 否决状态 - 仅投票结束返回
    uint CODE_ERR_ISVOTED = 3001; // 已经投票过
    uint CODE_ERR_PERMISSION = 3002; // 权限不足
    uint CODE_ERR_NOTFOUNDVOTETOPIC = 3003; // 未找到投票主题
    // uint CODE_ERR_VOTETOPICISEXIST = 3004; // 当前投票主题已存在
    uint CODE_ERR_INVALIDOPERATION = 3005; // 针对投票 - 无效操作

    // 投票内容
    struct VoteType {
        bytes32 voteTopic; // 投票主题
        address initiator; // 发起人
        uint agreeCount; // 赞成票
        uint opposeCount; // 否决票
        bool status; // 投票状态 true:标识开启 | false:标识结束
    }
    VoteType[] voteTypes; // 所有投票
    mapping(bytes32 => uint) voteIndexs; // 投票索引map (投票主题 => 投票索引)

    struct VoteOption {
        bool voteOpt; // 投票选项 true:标识赞成 | false:标识反对
        bool voted; // 若为真，代表该人已投票
    }

    struct Voter {
        mapping(uint => VoteOption) voteOption; // 投票索引 => 投票信息
    }
    mapping(address => Voter) voters; // 投票人地址 => 投票人

    // 构造函数 初始化投票
    constructor() {}

    /**
     * 投票方法
     */
    function vote(uint voteIndex, bool votvoteOption) public returns(uint) {
        Voter storage sender = voters[msg.sender];
        if (sender.voteOption[voteIndex].voted) {
            // 已经投票过
            return CODE_ERR_ISVOTED;
        } else {
            sender.voteOption[voteIndex] = VoteOption(votvoteOption, true);
            if (votvoteOption) {
                voteTypes[voteIndex].agreeCount++;
            } else {
                voteTypes[voteIndex].opposeCount++;
            }

            return CODE_SUCCESS;
        }
    }

    // 投票主题状态
    enum voteOperate {
        start,
        end
    }



    /**
     * 投票操作方法 (开始某场投票|结束某场投票)
     */
    function operateVote(voteOperate operate, bytes32 voteTopic) public returns(uint) {
        if (operate == voteOperate.start) {
            // 开始投票
            if (voteTypes.length == 0) {
                // 投票主题数组里没内容 - 新增的投票主题
                voteTypes.push(VoteType(voteTopic, msg.sender, 0, 0, true));
                voteIndexs[voteTopic] = voteTypes.length;
            } else {
                if (voteIndexs[voteTopic] != 0) {
                    // 当前投票主题存在
                    if (voteTypes[voteIndexs[voteTopic] - 1].initiator != msg.sender) {
                        return CODE_ERR_PERMISSION;
                    }
                    if (!voteTypes[voteIndexs[voteTopic] - 1].status) {
                        voteTypes[voteIndexs[voteTopic] - 1].status = true;
                    }
                } else {
                    // 新增的投票主题
                    voteTypes.push(VoteType(voteTopic, msg.sender, 0, 0, true));

                    voteIndexs[voteTopic] = voteTypes.length;
                }
            }
        } else if (operate == voteOperate.end) {
            if (voteIndexs[voteTopic] == 0) {
                return CODE_ERR_NOTFOUNDVOTETOPIC;
            }
            if (voteTypes[voteIndexs[voteTopic] - 1].initiator != msg.sender) {
                return CODE_ERR_PERMISSION;
            }
            // 结束投票
            if (voteTypes[voteIndexs[voteTopic] - 1].status) {
                voteTypes[voteIndexs[voteTopic] - 1].status = false;
            }
            uint allCount = 0; // 总人数
            uint voteTypesLength = voteTypes.length;
            for (uint i = 0; i < voteTypesLength; i++) {
                allCount += voteTypes[i].agreeCount;
                allCount += voteTypes[i].opposeCount;
            }

            // 计算当前投票所占比
            uint currentAgreeCount = voteTypes[voteIndexs[voteTopic] - 1].agreeCount;
            uint currentOpposeCount = voteTypes[voteIndexs[voteTopic] - 1].opposeCount;
            if ((currentAgreeCount + currentOpposeCount) * 3 > 2 * allCount) {
                // 当前主题投票数大于总数的 2/3
                if (currentAgreeCount > currentOpposeCount) {
                    // 当前赞成票大于否决票
                    return CODE_VOTE_AGREE;
                }
            }
            return CODE_VOTE_REJECT;

        } else {
            // 无效操作
            return CODE_ERR_INVALIDOPERATION;
        }

        return CODE_SUCCESS;
    }
}