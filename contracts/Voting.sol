// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Voting{
    // Announcement of candidate

    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }


    // Election with properties

    struct Election{
        uint id;
        string name;
        bool isActive;
        uint endTime;
        mapping(uint => Candidate) candidates;
        uint candidateCount;
        mapping(address => bool) hasVoted;
        uint totalVotes;
    }

    address public admin;
    uint public electionCount;
    mapping(uint => Election) public elections;

    event ElectionCreated(uint indexed electionId, string name, uint endTime);
    event CandidateAdded(uint indexed electionId, uint indexed CandidateId, string name);
    event VoteCast(uint indexed electionId, uint indexed candidateId);
    event ElectionEnded(uint indexed electionId, uint indexed winnderId, string winnerName, uint voteCount);

    modifier onlyAdmin(){
        require(msg.sender == admin, "Only admin can perform this operation");
        _;
    }

    modifier electionExist(uint _electionId){
        require(_electionId > 0 && _electionId <= electionCount, "Election doesn't exist");
        _;
    }

    modifier electionActive(uint _electionId){
        require(elections[_electionId].isActive, "Election is not active");
        require(block.timestamp < elections[_electionId].endTime, "Election has ended");
        _;
    }

    constructor(){
        admin = msg.sender;
    }

    function createElection(string memory _name, uint _duration) public onlyAdmin{
        electionCount++;
        Election storage election = elections[electionCount];
        election.id = electionCount;
        election.name = _name;
        election.isActive = true;
        election.endTime = block.timestamp + _duration;

        emit ElectionCreated(electionCount, _name, election.endTime);
    }

    function addCandidate(uint _electionId, string memory _name) public onlyAdmin electionExist(_electionId) electionActive(_electionId){
        Election storage election = elections[_electionId];
        election.candidateCount++;
        election.candidates[election.candidateCount] = Candidate(election.candidateCount, _name, 0);

        emit CandidateAdded(_electionId, election.candidateCount, _name);
    }

    function vote(uint _electionId, uint _candidateId) public electionExist(_electionId) electionActive(_electionId){
        Election storage election = elections[_electionId];
        require(!election.hasVoted[msg.sender], "You have voted already");
        require(_candidateId > 0 && _candidateId <= election.candidateCount, "You have choosen wrong candidate");

        election.hasVoted[msg.sender] = true;
        election.candidates[_candidateId].voteCount++;
        election.totalVotes++;

        emit VoteCast(_electionId, _candidateId);
    }

    function endElection(uint _electionId) public onlyAdmin electionExist(_electionId) electionActive(_electionId){
        Election storage election = elections[_electionId];
        election.isActive = false;

        uint winningVoteCount = 0;
        uint winningCandidateId = 0;

        for(uint i=1; i<election.candidateCount; i++){
            if(election.candidates[i].voteCount > winningVoteCount){
                winningVoteCount = election.candidates[i].voteCount;
                winningCandidateId = i;
            }
        }

        emit ElectionEnded(_electionId, winningCandidateId, election.candidates[winningCandidateId].name, winningVoteCount);
    }

    function getCandidate(uint _electionId, uint _candidateId) public view electionExist(_electionId) returns (string memory, uint){
        Election storage election = elections[_electionId];
        Candidate storage candidate = election.candidates[_candidateId];

        return (candidate.name, candidate.voteCount);
    }

    function getTotalVotes(uint _electionId) public view electionExist(_electionId) returns(uint){
        return elections[_electionId].totalVotes;
    }

    function getWinner(uint _electionId) public view electionExist(_electionId) returns(string memory winnerName, uint winnerVoteCount){
        Election storage election = elections[_electionId];

        uint winningVoteCount = 0;
        uint winningCandidateId = 0;

        for(uint i=1; i<=election.candidateCount; i++){
            if(election.candidates[i].voteCount > winningVoteCount){
                winningVoteCount = election.candidates[i].voteCount;
                winningCandidateId = i;
            }

            return (election.candidates[winningCandidateId].name, winningVoteCount);
        }
    }

}