// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 题目1：创建一个名为Voting的合约，包含以下功能：
// 一个mapping来存储候选人的得票数
// 一个vote函数，允许用户投票给某个候选人
// 一个getVotes函数，返回某个候选人的得票数
// 一个resetVotes函数，重置所有候选人的得票数
contract Voting {
    mapping(string candidate => uint256 voteNum) public votes;
    string[] public candidates;

    function vote (string memory _candidate, uint256 _votes) public {
        bool exists = false;
        for (uint256 i = 0; i < candidates.length; i++) {
            // 字符串不能直接比较是否相等
            if (keccak256(bytes(candidates[i])) == keccak256(bytes(_candidate))) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            candidates.push(_candidate);
        }
        votes[_candidate] += _votes;
    } 

    function getVotes(string memory _candidate) public view returns (uint256) {
        return votes[_candidate];
    }


    function resetVotes() external  {
        for (uint256 i = candidates.length; i >= 1; i--) {
            // mapping重置推荐用delete重置值
            string memory candidate = candidates[i - 1];
            votes[candidate] = 0;
            candidates.pop();
        }
        // delete candidates;
    }
}

// 题目2：✅ 反转字符串 (Reverse String)
// 题目描述：反转一个字符串。输入 "abcde"，输出 "edcba"
contract ReverseString {
    // 不支持中文
    function reverse(string memory _str) public pure returns (string memory) {
        bytes memory _bytes = bytes(_str);
        uint256 len = _bytes.length;
        for (uint256 i = 0; i < len / 2; i++) {
            bytes1 temp = _bytes[i];
            _bytes[i] = _bytes[len - i - 1];
            _bytes[len - i - 1] = temp;
        }
        return string(_bytes);
    }
}

// 题目3：用 solidity 实现整数转罗马数字
// 罗马数字包含以下七种字符: I， V， X， L，C，D 和 M。
// 字符          数值
// I             1
// V             5
// X             10
// L             50
// C             100
// D             500
// M             1000
// 例如， 罗马数字 2 写做 II ，即为两个并列的 1 。12 写做 XII ，即为 X + II 。 27 写做  XXVII, 即为 XX + V + II 。

// 通常情况下，罗马数字中小的数字在大的数字的右边。但也存在特例，例如 4 不写做 IIII，而是 IV。数字 1 在数字 5 的左边，所表示的数等于大数 5 减小数 1 得到的数值 4 。同样地，数字 9 表示为 IX。这个特殊的规则只适用于以下六种情况：

// I 可以放在 V (5) 和 X (10) 的左边，来表示 4 和 9。
// X 可以放在 L (50) 和 C (100) 的左边，来表示 40 和 90。 
// C 可以放在 D (500) 和 M (1000) 的左边，来表示 400 和 900。
// 给定一个罗马数字，将其转换成整数。
// 示例 1:
// 输入: s = "III"
// 输出: 3
// 示例 2:
// 输入: s = "IV"
// 输出: 4
// 示例 3:
// 输入: s = "IX"
// 输出: 9
// 示例 4:
// 输入: s = "LVIII"
// 输出: 58
// 解释: L = 50, V= 5, III = 3.
// 示例 5:
// 输入: s = "MCMXCIV"
// 输出: 1994
// 解释: M = 1000, CM = 900, XC = 90, IV = 4.
 
// 提示：
// 1 <= s.length <= 15
// s 仅含字符 ('I', 'V', 'X', 'L', 'C', 'D', 'M')
// 题目数据保证 s 是一个有效的罗马数字，且表示整数在范围 [1, 3999] 内
// 题目所给测试用例皆符合罗马数字书写规则，不会出现跨位等情况。
// IL 和 IM 这样的例子并不符合题目要求，49 应该写作 XLIX，999 应该写作 CMXCIX 。
// 关于罗马数字的详尽书写规则，可以参考 罗马数字 - 百度百科。
contract RomanNumerals {
    
    function intToRoman(uint256 _num) public pure returns (string memory) {
        require(_num > 0 && _num < 4000, "Invalid number");
        string[13] memory symbols = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];
        uint256[13] memory values = [
            uint256(1000),
            uint256(900),
            uint256(500),
            uint256(400),
            uint256(100),
            uint256(90),
            uint256(50),
            uint256(40),
            uint256(10),
            uint256(9),
            uint256(5),
            uint256(4),
            uint256(1)
        ];
        
        string memory result;

        for (uint256 i = 0; i < 13;) {
            if (_num > values[i]) {
                result = string.concat(result, symbols[i]);
                _num -= values[i];
            } else if (_num == values[i]) {
                result = string.concat(result, symbols[i]);
                break;
            } else {
                i++;
            }
        }

        return result;
    }
}

// 题目4：用 solidity 实现罗马数字转数整数
contract Number {
    function RomanToInt(string memory romanNum) public pure returns (uint256) { 
        string[13] memory symbols = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];
        uint256[13] memory values = [
            uint256(1000),
            uint256(900),
            uint256(500),
            uint256(400),
            uint256(100),
            uint256(90),
            uint256(50),
            uint256(40),
            uint256(10),
            uint256(9),
            uint256(5),
            uint256(4),
            uint256(1)
        ];

        // 从最大值开始匹配，能匹配上就是对应的值相加即可
        uint256 result = 0;
        bytes memory romBytes = bytes(romanNum);
        uint256 startIndex = 0;
        for (uint256 i = 0; i < 13;) {
            if (startIndex >= romBytes.length) {
                break;
            }
            string memory symb = symbols[i];
            bytes memory symbBytes = bytes(symb);
            if (symbBytes.length == 1) {
                // 长度为1
                string memory temp = string(abi.encodePacked(romBytes[startIndex]));
                if (areStringsEqual(symb, temp)) {
                    result += values[i];
                    startIndex++;
                } else {
                    i++;
                }
            } else {
                // 长度为2
                if (startIndex + 1 >= romBytes.length) {
                    // 剩余位数不足，不可能匹配到，直接跳转下一个判断
                    i++;
                    continue;
                }
                string memory temp = string.concat(string(abi.encodePacked(romBytes[startIndex])), string(abi.encodePacked(romBytes[startIndex + 1])));
                if (areStringsEqual(symb, temp)) {
                    result += values[i];
                    startIndex = startIndex +2;
                } else {
                    i++;
                }
            }    
        }

        return result;
    }

    function areStringsEqual(string memory _str1, string memory _str2) internal pure returns (bool) {
        return keccak256(abi.encodePacked(_str1)) == keccak256(abi.encodePacked(_str2));
    }
}

// 题目5：合并两个有序数组 (Merge Sorted Array)
// 题目描述：将两个有序数组合并为一个有序数组。
contract MergeSortedArray {

    function mergeSortedArray(uint256[] memory arr1, uint256[] memory arr2) public pure returns (uint256[] memory){
        uint256 len1 = arr1.length;
        uint256 len2 = arr2.length;
        uint256[] memory result = new uint256[](len1 + len2);

        uint256 arr1Ind = 0;
        uint256 arr2Ind = 0;
        uint256 mergeInd = 0;

        while(arr1Ind < len1 && arr2Ind < len2) {
            if (arr1[arr1Ind] <= arr2[arr2Ind]) {
                result[mergeInd] = arr1[arr1Ind];
                mergeInd++;
                arr1Ind++;
            } else {
                result[mergeInd] = arr2[arr2Ind];
                mergeInd++;
                arr2Ind++;
            }
        }
        if (arr1Ind < len1) {
            while (arr1Ind < len1) {
                result[mergeInd] = arr1[arr1Ind];
                mergeInd++;
                arr1Ind++;
            }
        }
        if (arr2Ind < len2) {
            while (arr2Ind < len2) {
                result[mergeInd] = arr2[arr2Ind];
                mergeInd++;
                arr2Ind++;
            }
        }

        return result;
    }

}

// 题目6： 二分查找 (Binary Search)
// 题目描述：在一个有序数组中查找目标值。
contract BinarySearch{
    function binarySearch(uint256[] memory arr, uint256 search) external pure returns (int256) {
        uint256 binary;
        uint256 begin = 0;
        uint256 end = arr.length - 1;
        while(begin <= end) {
            binary = begin + (end - begin) / 2;
            if (search == arr[binary]) {
                return int256(binary);
            } else if (search > arr[binary]) {
                begin = binary + 1;
            } else {
                end = binary - 1;
            }
        }
        return -1;
    }
}