/*********************************
 * Author: Markus Schordan, 2012 *
 *********************************/

#include "AstTerm.h"
#include <iostream>

std::string nodeTypeName(SgNode* node) {
  if(node==0) {
    return "null";
  } else {
    std::string tid=typeid(*node).name();
    int j=0;
    while(tid[j]>='0' && tid[j]<='9') j++;
    tid=tid.substr(j,tid.size()-j);
    return tid;
  }
}

std::string astTermToMultiLineString(SgNode* node,int tab, int pos) {
  std::string tabstring;
  for(int t=0;t<pos;t++) tabstring+=" ";

  if(node==0) 
    return tabstring+"null";

  std::string s=tabstring+nodeTypeName(node);
  
  // address debug output
  std::stringstream ss;
  ss<<node;
  //s+="@"+ss.str();

  int arity=node->get_numberOfTraversalSuccessors();
  if(arity>0) {
    s+="(\n";
    for(int i=0; i<arity;i++) {
      SgNode* child = node->get_traversalSuccessorByIndex(i);   
      if(i!=0) s+=",\n";
      s+=astTermToMultiLineString(child,tab,pos+tab);
    }
    s+="\n"+tabstring+")";
  }
  return s;
}

std::string astTermWithNullValuesToString(SgNode* node) {
  if(node==0)
    return "null";
  std::string s=nodeTypeName(node);
  int arity=node->get_numberOfTraversalSuccessors();
  if(arity>0) {
    s+="(";
    for(int i=0; i<arity;i++) {
      SgNode* child = node->get_traversalSuccessorByIndex(i);   
      if(i!=0) s+=",";
      s+=astTermWithNullValuesToString(child);
    }
    s+=")";
  }
  return s;
}

std::string astTermWithoutNullValuesToDot(SgNode* root) {
  RoseAst ast(root);
  std::stringstream ss;
  ss << "digraph G {\n";
  for(RoseAst::iterator i=ast.begin().withoutNullValues();i!=ast.end();++i) {
    ss << "\"" << *i <<"\""<< "[label=\"" << nodeTypeName(*i)<< "\"];"<<std::endl;
    if(*i!=root) {
      ss << "\""<<i.parent() << "\"" << " -> " << "\"" << *i << "\""<<";" << std::endl; 
    }
  }
  ss<<"}\n";
  return ss.str();
}

std::string functionAstTermsWithNullValuesToDot(SgNode* root) {
  RoseAst ast(root);
  string fragments;
  for(RoseAst::iterator i=ast.begin();i!=ast.end();++i) {
	if(isSgFunctionDefinition(*i)) {
	  fragments+=astTermWithNullValuesToDotFragment(*i);
	}
  }
  return dotFragmentToDot(fragments);
}

std::string dotFragmentToDot(string fragment) {
  std::stringstream ss;
  ss << "digraph G {\n";
  ss << fragment;
  ss<<"}\n";
  return ss.str();
}
std::string astTermWithNullValuesToDot(SgNode* root) {
  std::stringstream ss;
  ss << "digraph G {\n";
  ss << astTermWithNullValuesToDotFragment(root);
  ss<<"}\n";
  return ss.str();
}

std::string astTermWithNullValuesToDotFragment(SgNode* root) {
  RoseAst ast(root);
  std::stringstream ss;
  for(RoseAst::iterator i=ast.begin().withNullValues();i!=ast.end();++i) {
    ss << "\"" << *i <<"\""
	   << "[label=\"" << nodeTypeName(*i);
	if(*i && (*i)->attributeExists("info")) {
	  AstAttribute* attr=(*i)->getAttribute("info");
	  ss<<attr->toString();
	  ss << "\""<<" style=filled color=lightblue ";
	} else {
	  ss << "\"";
	}
	ss<< "];"<<std::endl;
    if(*i!=root) {
      ss << "\""<<i.parent() << "\"" << " -> " << "\"" << *i << "\""<<";" << std::endl; 
    }
  }
  return ss.str();
}

std::string astTermToDot(RoseAst::iterator start, RoseAst::iterator end) {
  std::stringstream ss;
  SgNode* root=*start;
  long int visitCnt=1;
  ss << "digraph G {\n";
  std::string prevNode="";
  for(RoseAst::iterator i=start;i!=end;++i) {
    ss << "\"" << i.current_node_id() <<"\""<< "[label=\"" << visitCnt++ << ":";
    ss << nodeTypeName(*i);
    ss << "\"";
    if(*i==0)
      ss << ",shape=diamond";
    ss <<"];"<<std::endl;
    if(*i!=root) {
      ss << "\""<<i.parent_node_id() << "\"" << " -> " << "\"";
      ss << i.current_node_id();
      ss << "\""<<";" << std::endl; 
    }
    std::string currentNode=i.current_node_id();
    if(prevNode!="") {
      // add traversal edge
      ss << "\""<< prevNode << "\"" << " -> " << "\"" << currentNode << "\"" << "[color=\"red\", constraint=\"false\"];\n";      
    }
    prevNode=currentNode;

  }
  ss<<"}\n";
  return ss.str();
}
