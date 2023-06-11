from dataclasses import dataclass
from enum import Enum

class NodeType(Enum):
	ERA = "Eraser"
	CON = "Constructor"
	DUP = "Duplicator"
	
@dataclass
class Node:
	principal: Node
	def is_in_active_pair(self):
		return self.principal.principal is Node

@dataclass		
class EraseNode(Node):
	def reduce(self):
		self.principal = EraseNode(principal = self)
		
@dataclass
class ArityTwoNode(Node):
	one: Node
	two: Node
	
@dataclass
class DupNode(ArityTwoNode):
	pass

@dataclass
class ConNode(ArityTwoNode):
	pass

def reduce(node: Node):
	pass
	
if __name__ == '__main__':
	a = EraseNode(principal = EraseNode(principal = None))
	a.reduce()
