{Fractions v.1.0, aka Zlomky v.1.0
Charles University in Prague, Faculty of Mathematics and Physics, Obecna matematika, the first semester
Winter semester, school year 2016/2017
NMIN101 Programming I
Matvei Slavenko}

{*Abstract*}

{This programme renders mathematical formulae using pseudo graphics. The input for the programme is a mathematical formula, and the output is the same formula presented in pseudo graphics.
The programme has a simple command-line user interface. The user can set the input and output streams at his/her convenience: the programme could both use files and standard input-output system. The list of commands and their detailed descriptions are available in the internal help module of the programme.}

program fractions;

{*Block of code describing the data structures used in the programme*}

{Data structure used for representation of the processed expression as a tree. Type 'tree' represents the single node of a tree. Fields that are used in the structure:
	1. 'val' - actual value of the node, that would be printed out
	2. 'typ' - type of the node.
		'num' for numbers
		'/', '*', '+', '-' for operations
	3. 'height', 'width' - the height and the width of the expression, which is represented by this node (including the child nodes) measured in number of characters, that is needed to print the expression.
	4. 'x0', 'y0' - the initial positions, from which the expression represented by this node (including the child nodes) should be printed.
	Note: it is assumed, that the x-axis goes from the left to the right side of the screen; y-axis goes from the bottom of the screen to the top.
	5. 'left', 'right' - child nodes of the node. For leafs it is assumed that these values are equal to 'nil'.
	Note: considering the fact that in this particular programme unary operators are prohibited, each node either is a leaf, or have both left and right child nodes.
	6. 'parent' - the parent node of the node. For the root it is assumed that this value is equal to 'nil'.}
type pTree = ^tree;
	tree = record
	val, typ: String;
	height, width, x0, y0: Integer;
	left, right, parent: pTree;
	end;

{Data structure used for building a printing buffer. The procedures of adding the items to the data structure imply, that it is a priority queue, the priority is defined by the function 'compare()'. Fields that are used in the structure:
	1. 'data' - the pointer to the node, which is an actual item in the queue.
	2. 'prev', 'next' - pointers to the previous and to the next items in the queue.
	Note: it is assumed, that for the head of the queue the 'prev' value is 'nil'. For the tail of the queue the 'next' value is 'nil'.}
type pQueue = ^queue;
	queue = record
	data: pTree;
	prev, next: pQueue;
	end;

{*Block of code, describing the global variables used in the programme*}

{Variables related to the representation of the expression in the programme and parsing process.
	1. 'expression' - the root of the tree, which represents the actual expression being processed.
	2. 'curNode' - this variable is used during the parsing of the expression only. It points to the so-called 'current' position of the parser in the tree.
	3. 'pushBack' - a so-called pushback character, allowing to address to the next character in the input stream.
	Note: if there is no characters ahead (the end of the file has been reached), then pushBack = #0.}
var expression, curNode: pTree;
var pushBack: char;

{Variables related to the printing of the expression.
	1. 'printQ' - the pointer to the head of the printing buffer.
	2. 'printerX', 'printerY' - the current positions of the 'printing head', i.e. coordinates of the character box, where the next character would be printed in.
	Note: it is assumed, that the 'printing head' goes from the left to the right side of the screen, from the top to the bottom.
	3. 'inFolder', 'outFolder' - the paths to the input and output folders, written with double back-slashes ('\\') as separators, ending with two backslashes.
	Example: 'D:\\Ring\\Experiments\\University\\Zlomky\\Input\\'
	Note: for the standard input a shortcut 'stdin' is used. Symmetrically, the shortcut 'stdout' is used for the standard output.
	4. 'inF', 'outF' - the names of the input and the output files.
	Example: 'input.txt'}
var printQ: pQueue;
var printerX, printerY: Integer;
var inFolder, outFolder: String;
var inF, outF: Text;

{Variables related to the communication with user.
	1. 'mute' - if mute=True, then messages describing the stages of the programme's work will not be printed out. Default value is 'False'.
	2. 'inCommand' - the variable used for reading the commands entered by user.}
var mute: Boolean;
var inCommand: String;


{*Block of code with useful and helpful procedures and functions*}
function max(a,b: Integer): Integer;
	begin
		if(a >= b) then max := a
		else max := b;
	end;

function isNum(ch: char): Boolean;
	begin
		if ((ch <= ('9')) and (ch >= ('0'))) then isNum := true
		else isNum := false;
	end;

function isOp(ch: char): Boolean;
	begin
		if ((ch = ('+')) or (ch = ('-')) or (ch = ('*')) or (ch = ('/'))) then isOp := true
		else isOp := false;
	end;

function isBrac(ch: char): Boolean;
	begin
		if ((ch = '(') or (ch = ')')) then isBrac := true
		else isBrac := false;
	end;

{Function that is used for multiplying Strings.
	1. 'str' - the string, that needs to be multiplied.
	2. 'n' - the number of times, by which it is needed to multiply the string.
	Example: multrStr('MFF', 3) = 'MFFMFFMFF'.}
function multStr(str: String; n: Integer): String;
	var i: Integer;
	begin
		multStr := '';
		for i := 1 to n do begin
			multStr := multStr + str;
		end;
	end;

{*Block of code responsible for parsing of strings*}

{Initialisation of the 'parser'. Fills in the pushback character, creates the root node of the expression, ensures that the root node's parent and children are 'nil'. Sets the current node of the parser 'curNode' to the root node.
This procedure is to be called before performing any actions that use the pushback character. The procedure is called in the beginning of the 'parseFile()' procedure.}
procedure initParser();
	begin
		if eof(inF) then pushBack := #0 {init PushBack}
		else read(inF, pushBack);

		new(expression); {init tree, set root node as the current node}
		expression^.parent := nil;
		expression^.left := nil;
		expression^.right := nil;
		curNode := expression;
	end;

{The function returns the value that is stored in the variable 'pushBack'. Reads the next character from the input stream and stores it in the 'pushBack' variable. If the end of the file is reached, stores #0 to the 'pushBack' variable.}
function nextChar(): char;
	begin
		nextChar := pushBack;
		if eof(inF) then pushBack := #0
		else read(inF, pushBack);
	end;

{The function reads the next number. Note: number is understood as a sequence of digits written consecutively. The function is applicable if and only if the value stored in 'pushBack' is a digit. Otherwise the behaviour is undefined.}
function parseNum(): String;
	begin
		parseNum := '';
		while(isNum(pushBack)) do begin
			parseNum := parseNum + nextChar();
		end;
	end;

{The procedure puts the token to the tree representation of the expression being parsed. For the precise definition of the word token see the description of the 'nextToken()' function.
	'token' - the token to be put to the tree.}
procedure putToken(token: String);
	var node: pTree;
	begin
		if token = '(' then begin
			new(node);
			curNode^.left := node;
			node^.parent := curNode;
			curNode := node;
			end

		else if token = ')' then begin
			curNode := curNode^.parent;
			end

		else if (token = '+') or (token = '-') or (token = '*') or (token = '/') then begin
			curNode := curNode^.parent;
			curNode^.typ := token;
			curNode^.val := token;

			new(node);
			curNode^.right := node;
			node^.parent := curNode;
			curNode := curNode^.right;
			end
		else begin
			curNode^.typ := 'num';
			curNode^.val := token;
			end;
		end;

{The function reads and returns the next token from the input stream. Token could be:
	1. A string consisting of either a left or right bracket only, e.g. '(', ')'.
	2. A string consisting of one of the operator characters only, e.g. '/', '*', '+', '-'.
	3. A string consisting of digits only, e.g. '33', '35486'.
	Note: since the number token could contain only digits, the digital fractions are not allowed by the programme.}
function nextToken(): String;

	begin
		if (isBrac(pushBack) or isOp(pushBack)) then begin
			nextToken := nextChar();
		end
		else nextToken := parseNum();
	end;

{This procedure parses the input stream and builds the abstract syntax tree of an expression presented in the input. The input stream should be opened prior to calling of the procedure.}
procedure parseFile();
	var token: String;
	begin
		initParser();
		while pushBack <> #0 do begin
			token := nextToken();
			putToken(token);
		end;
	end;

{*Block of code responsible for calculating positions*}

{The function allows to define, whether the node is a left child or not. Returns 'True' if the parameter 'node' is a left child of its parent node. 'False' otherwise.
Note: the root node is not a child node for any other node. Thus, the function being called for the root node returns 'False'.
	'node' - the node to be tested.}
function isLeft(node: pTree): Boolean;
	begin
		if node^.parent = nil then isLeft := False

		else if node^.parent^.left = node then isLeft := True
		else isLeft := False;
	end;

{The function allows to define, whether the node is a right child or not. Returns 'True' if the parameter 'node' is a right child of its parent node. 'False' otherwise.
Note: the root node is not a child node for any other node. Thus, the function being called for the root node returns 'False'.
	'node' - the node to be tested.}
function isRight(node: pTree): Boolean;
	begin
		if node^.parent = nil then isRight := False

		else if node^.parent^.right = node then isRight := True
		else isRight := False;
	end;

{The function allows to define, whether the node is a root node or not. Returns 'True' if the parameter 'node' is a root node. 'False' otherwise.
	'node' - the node to be tested.}
function isRoot(node: pTree): Boolean;
	begin
		isRoot := False;
		if node^.parent = nil then isRoot := True;
	end;

{The procedure puts the brackets to the nodes of the tree using recursion. The brackets are put in 'semi-full' way. It means that each separate subexpression is closed into brackets, except for numbers and fractions. So, for example an expression '1+2' after processing will look like '(1+2)'. Whether an expression '1/2' would look like '1/2'. The brackets are added to the 'val' field of the nodes of the processed tree.
	'node' - the of the tree, which is to be processed.
	'valL', 'valR' - the number of left and right brackets that are to surround the expression. For the regular user's purposes default values 0,0 should be satisfying.}
procedure insertBrackets(node: pTree; valL, valR: Integer);
	var str: String;
	begin
		str := '';
		{Brackets are appended either to the numbers, or to the quotient.}
		if (node^.typ = '/') or (node^.typ = 'num') then begin
			if (node^.typ = 'num') then begin
				if (isLeft(node)) then begin
					str := multStr('(', valL);
					node^.val := str + node^.val;
				end
				else if (isRight(node)) then begin
					str := multStr(')', valR);
					node^.val := node^.val + str;
				end;
			end
			else begin
				{In case of a quotient we can't append the brackets directly to the 'val' field, because it would warp the width of the expression. Apart from this, the 'val' of the quotient is changed by the compulsory procedure 'fillVals()'. Instead of this we would store the number of brackets that are to be appended to the quotient in it's x0 field. That is safe, because the x0 is never used until printing of the expression. Besides, the field is changed only by 'prepareX()' procedure, which always should be invoked after the 'fillVals()' procedure.
				This trick allows us to avoid adding an extra field to the nodes of the tree.}
				if (isLeft(node)) then begin
					node^.x0 := valL;
				end
				else if (isRight(node)) then begin
					node^.x0 := valR;
				end
				else begin
					node^.x0 := 0;
				end;
				{The quotient should have absorbed all parentheses. So all its operands should begin the brackets inserting process with default 0, 0 values.}
				insertBrackets(node^.left, 0, 0);
				insertBrackets(node^.right, 0, 0);
			end;
		end
		else begin
			{Each time when we go down by one level in the tree we are to write another bracket. If we go to the left child, it's an opening bracket; in case of the right child, it's a closing bracket.}
			insertBrackets(node^.left, valL + 1, valR);
			insertBrackets(node^.right, valL, valR + 1);
		end;
	end;

{The procedure recursively calculates the height of the expression. For precise definition of the term 'height of the expression', see the description of the tree nodes' fields. 
The procedure uses the values that are stored in the 'val' fields of the nodes. Thus, these fields shouldn't be changed after the procedure was called. Otherwise the integrity, validity and consistency of the calculated data couldn't be guaranteed. Overwrites the 'height' fields of the nodes.
	'node' - the node of the expression to start from.}
procedure calculateHeights(node: pTree);
	begin
		if(node^.typ <> 'num') then begin
			calculateHeights(node^.left);
			calculateHeights(node^.right);

			{For the quotients the height is equal to the sum of the heights of its operands plus 1}
			if (node^.typ = '/') then begin
				node^.height := node^.left^.height + node^.right^.height + 1;
			end
			{For other operations the height is equal to the maximum height of its operands}
			else node^.height := max(node^.left^.height, node^.right^.height);
		end

		{For the numbers the height is 1}
		else node^.height := 1;
	end;

{The procedure recursively calculates the width of the expression. For precise definition of the term 'width of the expression', see the description of the tree nodes' fields. 
The procedure uses the values that are stored in 'val' fields of the nodes. Thus, these fields shouldn't be changed after the procedure was called. Otherwise the integrity, validity and consistency of the calculated data couldn't be guaranteed. Overwrites the 'width' fields of the nodes.
	'node' - the node of the expression to start from.}
procedure calculateWidths(node: pTree);
	begin
		if(node^.typ <> 'num') then begin
			calculateWidths(node^.left);
			calculateWidths(node^.right);

			{For the quotient, the width is equal to the maximum width of its operands +2 (spaces on each side) + number of brackets to be printed around}
			if (node^.typ = '/') then begin
				node^.width := max(node^.left^.width, node^.right^.width) + 2 + node^.x0;
			end
			{For other operations, the width is equal to the sum of the widths of its operands + 3 (the operator character plus 2 spaces around the operator character)}
			else node^.width := node^.left^.width + node^.right^.width + 3;
		end
		{For the number, its width is equal to the number of digits in it + number of brackets that are near of it. (Brackets should be appended to the 'val' field by 'insertBrackets()' procedure already.)}
		else node^.width := length(node^.val);
	end;

{The procedure recursively calculates the y0 values of the expression. For precise definition of the term 'y0 value of the expression', see the description of the tree nodes' fields. 
The procedure uses the values that are stored in the 'height' fields of the nodes. Thus, these fields shouldn't be changed after the procedure was called. Otherwise the integrity, validity and consistency of the calculated data couldn't be guaranteed. Overwrites the 'y0' fields of the nodes.
	'node' - the node of the expression to start from.
	'val' - the default position for the "printer's head". In general, the parameter is used for the recursion purposes only, the initial value could be random.}
procedure prepareY(node: pTree; val: Integer);
	begin
		{For number the y0 value is equal to the initial position of the printer's head.}
		if (node^.typ = 'num') then node^.y0 := val

		{For the quotient, the y0 value is calculated by the following rules.
		For the fraction line, the y0 value is equal to the initial position of the printer's head. The left operand is printed above the line, the right operand is printed below the line.}
		else if (node^.typ = '/') then begin
			node^.y0 := val;
			prepareY(node^.left, val + (node^.left^.height div 2) + 1);
			prepareY(node^.right, val - (node^.right^.height div 2) - 1);
			end

		{For other operations, the y0 value is equal to the y0 value of their left operand.}
		else begin
			prepareY(node^.left, val);
			node^.y0 := node^.left^.y0;
			prepareY(node^.right, val);
		end;
	end;

{The procedure recursively calculates the x0 values of the expression. For precise definition of the term 'x0 value of the expression', see the description of the tree nodes' fields.
The procedure uses the values that are stored in the 'width' fields of the nodes. Thus, these fields shouldn't be changed after the procedure was called. Otherwise the integrity, validity and consistency of the calculated data couldn't be guaranteed. Overwrites the 'x0' fields of the nodes.
	'node' - the node of the expression to start from.
	'val' - the default position for the "printer's head", which should be non-negative. It is recommended to use 0.}
procedure prepareX(node: pTree; val: Integer);
	var spanL, spanR: Integer;
	begin
		{For number, the x0 value is equal to the initial position of the printer's head.}
		if(node^.typ = 'num') then node^.x0 := val

		{For non-quotient operations, the x0 value is calculated by the following rules. The left operand is written starting from the initial position of the printer's head. The operator is printed starting from the position of the printer's head after printing the left operand, which is equal to the initial printer's head position plus the left operand's width. The operator's width is 3 characters (operator character plus two spaces around it).}
		else if(node^.typ <> '/') then begin
			prepareX(node^.left, val);
			node^.x0 := node^.left^.width + val;
			prepareX(node^.right, node^.x0 + 3);
		end
		{The fraction line's x0 value is equal to the initial printer's head position. The operands should be centred, span values are added for this purpose. We need to take into account the brackets too. This is why there is need to distinct the case when the quotient is a left child.}
		else begin
			spanL := (node^.width - node^.x0 - node^.left^.width) div 2;
			spanR := (node^.width - node^.x0 - node^.right^.width) div 2;

			if (isLeft(node)) then begin
				prepareX(node^.left, val + spanL + node^.x0);
				prepareX(node^.right, val + spanR + node^.x0);
				node^.x0 := val;
			end
			else begin
				prepareX(node^.left, val + spanL);
				node^.x0 := val;
				prepareX(node^.right, val + spanR);
			end;

		end;
	end;

{The procedure recursively calculates the 'val' values of the expression - the values, which are to be printed. For precise definition of the term 'val value of the expression', see the description of the tree nodes' fields.
The procedure uses the values that are stored in the 'width' and 'val' fields of the nodes. Thus, these fields shouldn't be changed after the procedure was called. Otherwise the integrity, validity and consistency of the calculated data couldn't be guaranteed. Overwrites the 'val' fields of the nodes.
	'node' - the node of the expression to start from.}
procedure fillVals(node: pTree);
	var i: Integer;
	var str: String;
	begin
		{If the node is a quotient, than we need to take care of the brackets. Besides, we need to calculate the length of the fraction line.}
		if (node^.typ = '/') then begin
			str := ' ';

			if (isLeft(node)) then begin
				str := str + multStr('(', node^.x0);
			end;

			str := str + multStr('-', node^.width - 2 - node^.x0);

			if (isRight(node)) then begin
				str := str + multStr(')', node^.x0);
			end;

			str := str + ' ';
			node^.val := str;

			fillVals(node^.left);
			fillVals(node^.right);
		end
		{If the node is a number, than we do need to do anything with it.}
		else if (node^.typ = 'num') then i := 0
		{If the node is a non-quotient operator, than we need to add spaces on both sides of the operator character.}
		else begin
			node^.val := ' ' + node^.typ + ' ';
			fillVals(node^.left);
			fillVals(node^.right);
		end;
	end;

{*Block of code responsible for printing of the expression*}

{The function defining the priorities and the order of the nodes in the printing queue. The nodes with the higher y0 values have priority over the nodes with the lower y0 values. In case the y0 values are equal, the nodes with the lower x0 value have priority over the nodes over the nodes with the higher x0 value.
	'a', 'b' - nodes to be compared.}
function compare(a,b: pQueue): Integer;
	begin
		if (b = nil) then compare := 1
		else if (a^.data^.y0 > b^.data^.y0) then compare := 1
		else if (a^.data^.y0 < b^.data^.y0) then compare := -1
		else if (a^.data^.x0 < b^.data^.x0) then compare := 1
		else if (a^.data^.x0 > b^.data^.x0) then compare := -1
		else compare := 0;
	end;

{The procedure adds the node to the printing buffer in accordance with the priorities defined by the 'compare()' function.
The 'x0' and 'y0' of the item being added should be calculated, otherwise the validity and correctness of the procedure's work are not guaranteed.
	'chunk' - the node to be added to the printing queue.}
procedure addToQ(chunk: pTree);
	var node, current, pom: pQueue;

	begin
		{Wrap the node to the queue item container}
		new(node);
		node^.data := chunk;
		node^.next := nil;
		node^.prev := nil;

		if printQ = nil then printQ := node
		{Walk along the queue until the place for the item is found. The item should be inserted before the 'current' item. We need to be careful in the situations when the 'current' item is the last one in the queue though.}
		else begin
			current := printQ;
			while (compare(node, current) = -1) and (current^.next <> nil) do begin
				current := current^.next;
			end;

			if current = printQ then begin
				if compare(node, current) = 1 then begin
					node^.next := printQ;
					printQ^.prev := node;
					printQ := node;
				end
				else begin
					current^.next := node;
					node^.prev := current;
				end;
			end
			else if compare(node, current) = 1 then begin
				node^.next := current;
				node^.prev := current^.prev;
				current^.prev := node;

				pom := node^.prev;

				pom^.next := node;
			end
			else begin
				current^.next := node;
				node^.prev := current;
			end;
		end;
	end;

{The procedure recursively puts all the nodes of expression to the printing buffer.
The 'x0' and 'y0' values should be calculated for each node of the tree.
	'node' - the node to start the process from.}
procedure fillQ(node: pTree);
	begin
		if (node^.typ = 'num') then addToQ(node)
		else begin
			fillQ(node^.left);
			addToQ(node);
			fillQ(node^.right);
		end;
	end;

{The procedure puts the printer's head to the beginning of a new line.}
procedure nextLine();
	begin
		writeln(outF, '');
		printerX := 0;
		printerY := printerY - 1;
	end;

{The procedure puts the printer's head to the x-coordinate, from which the 'item' item should be printed.
Note: the procedure should be called after the 'adjustY()' procedure, since 'adjustY()' resets the x-position of the printer's head.
	'item' - the benchmark for adjusting the coordinate.}
procedure adjustX(item: pQueue);
	var i, dif: Integer;

	begin
		dif := item^.data^.x0 - printerX;

		for i := 1 to dif do begin
			printerX := printerX + 1;
			write(outF, ' ');
		end;
	end;

{The procedure puts the printer's head to the y-coordinate (basically to the line), where the 'item' item should be printed.
Note: resets the printer's head x-coordinate to 0. Thus should be called before the 'adjustX()' procedure.
	'item' - the benchmark for adjusting the coordinate.}
procedure adjustY(item: pQueue);
	var i, dif: Integer;
	begin
		dif := abs(item^.data^.y0 - printerY);

		for i := 1 to dif do begin
			nextLine();
		end;
	end;

{The procedure prints the items in the buffer. The x0 and y0 are considered in the process of printing.
	'buffer' - the buffer to be print out.}
procedure print(buffer: pQueue);
	var item: pQueue;
	begin
		printerX := 0;
		printerY := buffer^.data^.y0;
		item := buffer;

		while (item <> nil) do begin
			adjustY(item);
			adjustX(item);
			printerX := printerX + length(item^.data^.val);
			write(outF, item^.data^.val);
			item := item^.next;
		end;
		writeln(outF, '');
	end;

{*Block of code responsible for preparation of external resources*}

{The procedure prepares the external resources: assigns the files on the disk to the proper variables and opens them.}
procedure prepareSources(inPath, outPath: String);
	begin
		if (inFolder <> 'stdin') then begin
			assign(inF, inFolder + inPath);
			reset(inF);
		end
		else begin
			inF := Input;
			writeln('Type the expression to be processed. Finish the expression by ctrl+z:');
		end;
		if (outFolder <> 'stdout') then begin
			assign(outF, outFolder + outPath);
			rewrite(outF);
		end
		else outF := Output;
	end;

{The procedure closes the external resources.}
procedure closeSources();
	begin
		if (inFolder <> 'stdin') then close(inF);
		if (outFolder <> 'stdout') then close(outF);
	end;

{*Block of code responsible for communications with the user*}

{The simple procedure for printing out messages to the stdout stream. Messages will not be printed if 'mute = True'.}
procedure status(str: String);
	begin
		if not mute then writeln(str);
	end;

{The procedure assembles the separate procedures and subprograms to a single block of code. It processes the expression got from the input stream, transforms it to a graphical representation, prints the result to the output stream and flushes the variable, preparing them for the next usage.
	'inFile', 'outFile' - the names of the input and output files.}
procedure process(inFile, outFile: String);
	begin
		status('Starting rendering');
		prepareSources(inFile, outFile);

		parseFile();
		status('Finished parsing');

		insertBrackets(expression, 0, 0);
		calculateWidths(expression);
		fillVals(expression);
		calculateHeights(expression);
		prepareY(expression, 0);
		prepareX(expression, 0);
		status('Finished calculating graphic parameters');

		fillQ(expression);
		print(printQ);
		status('Finished printing out the expression');

		printQ := nil;
		expression := nil;
		curNode := nil;
		status('Finished deleting data');

		closeSources();
		status('Files are closed');
		status('Processing finished');
		status('');
	end;

procedure prcs();
	var path1, path2: String;
	begin
		if(inFolder <> 'stdin') then begin
				write('Enter the name of the input file: ');
				readln(path1);
				writeln('');
			end
			else writeln('Input: stdin');

			if(outFolder <> 'stdout') then begin
				write('Enter the name of the output file: ');
				readln(path2);
			end
			else writeln('Output: stdout');

			process(path1, path2);
	end;

procedure printIntro();
	begin
		writeln('');
		writeln('Fractions v.1.0, aka Zlomky v.1.0');
		writeln('');
		writeln('Charles University in Prague, Faculty of Mathematics and Physics');
		writeln('Winter semester, school year 2016/2017');
		writeln('Matvei Slavenko, Obecna matematika, the first year');
		writeln('NMIN101 Programming I');


		writeln('Use "?" or "help" to get the list of commands and their description.');
		writeln('************************************');
		writeln('');
	end;

procedure printSettings();
	begin
		writeln('Current path to the input folder is:');
		writeln(inFolder);
		writeln();
		writeln('Current path to the output folder is:');
		writeln(outFolder);
		writeln();
		write('Mute: ');
		writeln(mute);
	end;

procedure help();
	begin
		writeln('Main commands:');
		writeln('* prcs - process. The command starts the formula rendering process.');		
		writeln('* q, exit - quit. Use this command to quit the programme.');
		writeln('');

		writeln('Informative commands:');
		writeln('* sets - settings. Prints the current input and output folders, and the mute setting.');
		writeln('* credits. Prints the short information about the programme.');
		writeln('');

		writeln('Commands related to the programme settings:');
		writeln('* chgin - change input folder. Use this command to change the setting. Use "\\" as a separator. The path to the folder should finish with "\\".');
		writeln('* chgout - change output folder. Use this command to change the setting. Use "\\" as a separator. The path to the folder should finish with "\\".');
		writeln('* mute. Mutes the messages related to the rendering process printed by the "prcs" command.');
		writeln('* unmute. Allows the "prcs" command to print the messages related to the rendering process.');
		writeln('');
	end;

procedure unknownCommand();
	begin
		writeln('Unknown command. Use "?" or "help" to get the list of commands and their descriptions.');
	end;

procedure changeInFolder();
	var path1: String;
	begin
		write('Enter the name of the new input folder. Use "stdin" as a shortcut for the standard input: ');
		readln(path1);
		writeln();
		inFolder := path1;
	end;

procedure changeOutFolder();
	var path1: String;
	begin
		write('Enter the name of the new output folder. Use "stdout" as a shortcut for the standard output: ');
		readln(path1);
		writeln();
		outFolder := path1;
	end;

{The procedure processes the command that was typed by user. The control is passed to the relevant procedure or subprogram. If the command is not in the list, the procedure 'unknownCommand()' will be called.
	'com' - the command to be processed.}
procedure processCommand(com: String);
	begin
		if (com = 'help') or (com = '?') then help()
		else if (com = 'prcs') then prcs()
		else if (com = 'credits') then printIntro()
		else if (com = 'sets') then printSettings()
		else if (com = 'chgin') then changeInFolder()
		else if (com = 'chgout') then changeOutFolder()
		else if (com = 'q') or (com = 'exit') then com := com {Do nothing}
		else if (com = 'mute') then mute := True
		else if (com = 'unmute') then mute := False
		else unknownCommand();
	end;

{*Main method*}

{The actual body of the programme. Sets the default values for the 'inFolder' and 'outFolder' variables, prints out the information about the programme and the current settings, launches the standard working loop of the programme.}
begin

	inFolder := 'D:\\Ring\\Experiments\\University\\Zlomky\\Input\\';
	outFolder := 'D:\\Ring\\Experiments\\University\\Zlomky\\Output\\';

	printIntro();
	printSettings();

	repeat
		readln(inCommand);
		processCommand(inCommand)

	until (inCommand = 'q') or (inCommand = 'exit');
end.
