// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract InternshipMarketplace {
    address public admin;

    struct Internship {
        string companyName;
        string role;
        string description;
        uint256 stipend;
        address employer;
        bool isActive;
    }

    struct Application {
        address student;
        string resumeHash;
        bool approved;
        bool exists;
    }

    mapping(uint256 => Internship) public internships;
    mapping(uint256 => mapping(address => Application)) public applications;
    uint256 public internshipCount;

    event InternshipPosted(uint256 internshipId, string companyName, string role, address employer);
    event ApplicationSubmitted(uint256 internshipId, address student);
    event ApplicationApproved(uint256 internshipId, address student);
    event StipendPaid(uint256 internshipId, address student, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can execute this");
        _;
    }

    modifier onlyEmployer(uint256 _internshipId) {
        require(msg.sender == internships[_internshipId].employer, "Only the employer can execute this");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function postInternship(string calldata _companyName, string calldata _role, string calldata _description, uint256 _stipend) external {
        internships[internshipCount] = Internship({
            companyName: _companyName,
            role: _role,
            description: _description,
            stipend: _stipend,
            employer: msg.sender,
            isActive: true
        });

        emit InternshipPosted(internshipCount, _companyName, _role, msg.sender);
        internshipCount++;
    }

    function applyForInternship(uint256 _internshipId, string calldata _resumeHash) external {
        require(internships[_internshipId].isActive, "Internship is no longer active");
        require(!applications[_internshipId][msg.sender].exists, "You have already applied for this internship");

        applications[_internshipId][msg.sender] = Application({
            student: msg.sender,
            resumeHash: _resumeHash,
            approved: false,
            exists: true
        });

        emit ApplicationSubmitted(_internshipId, msg.sender);
    }
    
    function approveApplication(uint256 _internshipId, address _student) external onlyEmployer(_internshipId) {
        require(applications[_internshipId][_student].exists, "Application does not exist");

        applications[_internshipId][_student].approved = true;

        emit ApplicationApproved(_internshipId, _student);
    }

    function payStipend(uint256 _internshipId, address _student) external onlyEmployer(_internshipId) {
        require(applications[_internshipId][_student].approved, "Application not approved");

        uint256 stipend = internships[_internshipId].stipend;
        (bool sent, ) = _student.call{value: stipend}("");
        require(sent, "Failed to send stipend");

        emit StipendPaid(_internshipId, _student, stipend);
    }

    function deactivateInternship(uint256 _internshipId) external onlyEmployer(_internshipId) {
        internships[_internshipId].isActive = false;
    }

    receive() external payable {} // Fallback to receive funds
}
