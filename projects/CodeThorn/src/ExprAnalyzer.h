#ifndef EVAL_EXPR_H
#define EVAL_EXPR_H

/*************************************************************
 * Copyright: (C) 2012 by Markus Schordan                    *
 * Author   : Markus Schordan                                *
 * License  : see file LICENSE in the CodeThorn distribution *
 *************************************************************/

#include <limits.h>
#include <string>
#include "StateRepresentation.h"
#include "VariableIdMapping.h"
#include "AType.h"

using namespace std;

class SingleEvalResult {
 public:
  EState eState;
  AType::BoolLattice result;
  bool isTop() {return result.isTop();}
  bool isTrue() {return result.isTrue();}
  bool isFalse() {return result.isFalse();}
  bool isBot() {return result.isBot();}
};

class SingleEvalResultConstInt {
 public:
  EState eState;
  ConstraintSet exprConstraints; // temporary during evaluation of expression
  AType::ConstIntLattice result;
  AValue value() {return result;}
  bool isConstInt() {return result.isConstInt();}
  bool isTop() {return result.isTop();}
  bool isTrue() {return result.isTrue();}
  bool isFalse() {return result.isFalse();}
  bool isBot() {return result.isBot();}
};

class ExprAnalyzer {
 public:
  SingleEvalResult eval(SgNode* node,EState eState);
  //! Evaluates an expression using ConstIntLattice and returns a list of all evaluation-results.
  //! There can be multiple results if one of the variables was bound to top as we generate
  //! two different states and corresponding constraints in this case, one representing the
  //! true-case the other one repreenting the false-case.
  //! When the option useConstraints is set to false constraints are not used when determing the
  //! values of top-variables. 
  list<SingleEvalResultConstInt> evalConstInt(SgNode* node,EState eState, bool useConstraints, bool safeConstraintPropagation);
  //! returns true if node is a VarRefExp and sets varName=name, otherwise false and varName="$".
  static bool variable(SgNode* node,VariableName& varName);
  //! returns true if node is a VarRefExp and sets varId=id, otherwise false and varId=0.
  static bool variable(SgNode* node,VariableId& varId);

 private:
  //! evaluates an expression (whithout maintaining state information)
  AValue pureEvalConstInt(SgNode* node,EState& eState);
};

#endif