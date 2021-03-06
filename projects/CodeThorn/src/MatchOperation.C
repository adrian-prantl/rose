/*************************************************************
 * Copyright: (C) 2012 Markus Schordan                       *
 * Author   : Markus Schordan                                *
 * License  : see file LICENSE in the CodeThorn distribution *
 *************************************************************/

#include "MatchOperation.h"

bool
MatchOperation::performOperation(MatchStatus&  status, RoseAst::iterator& i, SingleMatchResult& smr) {
  std::cout<<"performing default operation.\n";
  return true;
}

std::string
MatchOpSequence::toString() {
  std::string s;
  if(size()==0) 
    return "sequence(empty)";
  for(MatchOpSequence::iterator i=begin();i!=end();i++) {
    if(i!=begin()) 
      s+=",";
    s+=(*i)->toString();
  }
  return "sequence("+s+")";
}

std::string
MatchOpOr::toString() {
  return std::string("or(")+_left->toString()+","+_right->toString()+"),\n";
}
bool
MatchOpOr::performOperation(MatchStatus& status, RoseAst::iterator& i, SingleMatchResult& smr) {
  RoseAst::iterator tmp_iter_left=i;
  RoseAst::iterator tmp_iter_right=i;
  SingleMatchResult left_smr;
  SingleMatchResult right_smr;
  bool left_result=_left->performOperation(status,tmp_iter_left,left_smr);
  bool right_result=_right->performOperation(status,tmp_iter_right,right_smr);
  if(left_result && right_result) {
    //    status.mergeSingleMatchResult(left_smr);
    //status.mergeSingleMatchResult(right_smr);
    // we do not assign tmp_iter_left (both are correct)
    i=tmp_iter_right;
    return true;
  }
  if(left_result) {
    i=tmp_iter_left;
    status.mergeSingleMatchResult(left_smr);
    return true;
  }
  if(right_result) {
    i=tmp_iter_right;
    status.mergeSingleMatchResult(right_smr);
    return true;
  }
  return false;
}

MatchOpVariableAssignment::MatchOpVariableAssignment(std::string varName):_varName(varName){}

std::string 
MatchOpVariableAssignment::toString() {
  return "variable_assignment("+_varName+")";
}

bool
MatchOpVariableAssignment::performOperation(MatchStatus&  status, RoseAst::iterator& i, SingleMatchResult& smr) {
  SgNode* node=*i;
  if(status.debug)
    std::cout << "VariableAssignment: "<<_varName<<"="<<node;
  smr.singleMatchVarBindings[_varName]=node;
  return true;
}

MatchOpCheckNode::MatchOpCheckNode(std::string nodename) {
  // convert name to same format as typeid provides;
  std::stringstream ss;
  ss << nodename.size();
  ss << nodename;
  _nodename=ss.str();
}

std::string
MatchOpCheckNode::toString() {
  return "check_node("+_nodename+")";
}

bool
MatchOpCheckNode::performOperation(MatchStatus&  status, RoseAst::iterator& i, SingleMatchResult& smr) {
  if(status.debug)
    std::cout << "CheckNode: ";
  SgNode* node=*i;
  if(node!=0) {
    // determine type name of node
    std::string nodeTypeName=typeid(*node).name();
    if(status.debug)
      std::cout << "(" << _nodename << "," << nodeTypeName <<")";
    return nodeTypeName==_nodename;
  } else {
    if(status.debug)
      std::cout << "(" << _nodename << "," << "null" <<")";
    return false;
  }
}

MatchOpCheckNodeSet::MatchOpCheckNodeSet(std::string nodenameset) {
  // convert name to same format as typeid provides;
  _nodenameset=nodenameset;
}

std::string
MatchOpCheckNodeSet::toString() {
  return "check_node_set("+_nodenameset+")";
}

bool
MatchOpCheckNodeSet::performOperation(MatchStatus&  status, RoseAst::iterator& i, SingleMatchResult& smr) {
  if(status.debug)
    std::cout << "CheckNodeSet: ";
  SgNode* node=*i;
  if(node!=0) {
    // determine type name of node
    std::string nodeTypeName=typeid(*node).name();
    if(status.debug)
      std::cout << "(" << _nodenameset << "," << nodeTypeName <<")";
    // TODO: check of all names of the nodenameset
    return false;
  } else {
    if(status.debug)
      std::cout << "(" << _nodenameset << "," << "null" <<")";
    return false;
  }
}


MatchOpArityCheck::MatchOpArityCheck(size_t arity):_minarity(arity),_maxarity(arity) {
}
MatchOpArityCheck::MatchOpArityCheck(size_t minarity, size_t maxarity):_minarity(minarity),_maxarity(maxarity) {
}

std::string 
MatchOpArityCheck::toString() {
  std::stringstream ss;
  if(_minarity==_maxarity)
    ss<<_minarity;
  else
    ss<<_minarity<<","<<_maxarity;
  return "arity_check("+ss.str()+")";
}

bool
MatchOpArityCheck::performOperation(MatchStatus&  status, RoseAst::iterator& i, SingleMatchResult& smr) {
  if(status.debug)
    std::cout << "ArityCheck: ";
  SgNode* node=*i;
  if(node!=0) {
    size_t nodeArity=node->get_numberOfTraversalSuccessors();
    if(status.debug)
      std::cout<<"("<<_minarity<<":"<<_maxarity<<","<<nodeArity<<")";
    return (nodeArity>=_minarity && nodeArity<=_maxarity);
  } else {
    if(status.debug)
      std::cout<<"("<<_minarity<<":"<<_maxarity<<","<<"0"<<")";
    return _minarity==0 && _maxarity==0;
  }
}


MatchOpForward::MatchOpForward() {}
std::string MatchOpForward::toString() {
  return "forward()";
}
bool MatchOpForward::performOperation(MatchStatus& status, RoseAst::iterator& i, SingleMatchResult& smr) {
  if(status.debug)
    std::cout << "forward()";
  ++i;
  return true;
}

MatchOpSkipChildOnForward::MatchOpSkipChildOnForward() {}
std::string MatchOpSkipChildOnForward::toString() {
  return "skip_child_on_forward()";
}
bool MatchOpSkipChildOnForward::performOperation(MatchStatus& status, RoseAst::iterator& i, SingleMatchResult& smr) {
  if(status.debug)
    std::cout << "skip_child_on_forward";
  SgNode* node=*i;
  if(status.debug)
    std::cout << "-OK1-";
  i.skipChildrenOnForward();
  ++i;
  if(status.debug)
    std::cout << "-OK2-";
  if(status.debug) {
    std::cout << "("<<node<<"->";
    if(!i.is_past_the_end())
      std::cout<<*i<<")";
    else
      std::cout<<"past-the-end."<<")";
  }
  return true;
}

MatchOpMarkNode::MatchOpMarkNode() {}
std::string MatchOpMarkNode::toString() {
  return "mark_node()";
}
bool MatchOpMarkNode::performOperation(MatchStatus& status, RoseAst::iterator& i, SingleMatchResult& smr) {
  SgNode* node=*i;
  if(status.debug)
    std::cout << "mark_node("<<node<<")";
  smr.singleMatchMarkedLocations.push_front(i);
  return true;
}

MatchOpCheckNull::MatchOpCheckNull() {}
std::string MatchOpCheckNull::toString() {
  return "null";
}
bool MatchOpCheckNull::performOperation(MatchStatus&  status, RoseAst::iterator& i, SingleMatchResult& smr) {
  if(status.debug)
    std::cout << "check_null";
  return (*i)==0;
}

MatchOpDotDot::MatchOpDotDot() {}
std::string MatchOpDotDot::toString() {
  return "dotdot";
}
bool MatchOpDotDot::performOperation(MatchStatus&  status, RoseAst::iterator& i, SingleMatchResult& smr) {
  if(status.debug)
    std::cout << "dotdot";
  return true;
}

bool MatchOpSequence::performOperation(MatchStatus& status, RoseAst::iterator& i, SingleMatchResult& vb) {
  if(status.debug)
    std::cerr << "match_sequence:";

  /* an empty sequence does not not match (therefore we return true) but
     it also does not modify the state (as not vars can be added nor can
     matched locations be added)
  */
  if(this->size()==0) {
    if(status.debug)
      std::cerr << "empty-sequence;";
    return true;
  }
  SingleMatchResult smr; // we intentionally avoid dynamic allocation for var-bindings of a single pattern
  //MatchStatus tmp_status=status; // create tmp copy of status [TODO: not used yet!]
  RoseAst::iterator tmp_pattern_ast_iter=i; // create tmp copy of iter
  for(MatchOperationList::iterator match_op_iter=this->begin();
      match_op_iter!=this->end();
      match_op_iter++) {
    bool tmpresult=(*match_op_iter)->performOperation(status, tmp_pattern_ast_iter, smr);
    if(!tmpresult) {
      // matchVarBindings and matchRegisteredIterators is automatically deleted if we return with false
      if(status.debug)
	std::cerr << "not matched;";
      return false;
    }
  }

  // pattern has been successfully matched
  // on a successful match we need to update the ast-iterator now
  i=tmp_pattern_ast_iter;
  // not tested yet: we do not do vb=smr because of merging marked locs?
  status.mergeSingleMatchResult(smr);
  //status._allMatchVarBindings->push_back(smr.singleMatchVarBindings);
  //status._allMatchMarkedLocations.splice(status._allMatchMarkedLocations.end(),smr.singleMatchMarkedLocations); // move elements (instead of copy)
  if(status.debug)
    std::cout << "sucessfully matched;";
  return true;
}

void MatchStatus::mergeOtherStatus(MatchStatus& other) {
  for(std::list<SingleMatchVarBindings>::iterator i=other._allMatchVarBindings->begin();
      i!=other._allMatchVarBindings->end();
      ++i) {
    _allMatchVarBindings->push_back(*i);
  }
  for(SingleMatchMarkedLocations::iterator i=other._allMatchMarkedLocations.begin();
      i!=other._allMatchMarkedLocations.end();
      ++i) {
    _allMatchMarkedLocations.push_back(*i);
  }
}

void MatchStatus::mergeSingleMatchResult(SingleMatchResult& other) {
  _allMatchVarBindings->push_back(other.singleMatchVarBindings);
  for(SingleMatchMarkedLocations::iterator i=other.singleMatchMarkedLocations.begin();
      i!=other.singleMatchMarkedLocations.end();
      ++i) {
    _allMatchMarkedLocations.push_back(*i);
  }
}

bool 
MatchStatus::isMarkedLocation(RoseAst::iterator& i) {
  // TODO: use find and make it more efficient (right now we have O(n))
  // we cannot use ordered sets because no operator< is defined on 
  // forward-iterators
  for(SingleMatchMarkedLocations::iterator j=_allMatchMarkedLocations.begin();
      j!=_allMatchMarkedLocations.end();
      ++j) {
    if(i==*j)
      return true;
  }
  return false;
}


void MatchStatus::addVarBinding(std::string varname,SgNode* node) {
  current_smr.singleMatchVarBindings[varname]=node;
}

void MatchStatus::addMarkedLocation(SgNode* node) {
  current_smr.singleMatchMarkedLocations.push_back(node);
}

void MatchStatus::commitSingleMatchResult() {
  _allMatchVarBindings->push_back(current_smr.singleMatchVarBindings);
  _allMatchMarkedLocations.splice(_allMatchMarkedLocations.end(),current_smr.singleMatchMarkedLocations); // move elements (instead of copy)
  current_smr.clear();
}

void SingleMatchResult::clear() {
  
}
