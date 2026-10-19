#ifndef AST_H
#define AST_H

#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <map>

using namespace std;

class ASTNode {
public:
    virtual ~ASTNode() {}
    virtual string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp, int& temp_count, int& label_count) const = 0;
};

// Expression node types

class ExprNode : public ASTNode {
protected:
    string node_type; // Type information (int, float, void, etc.)
public:
    ExprNode(string type) : node_type(type) {}
    virtual string get_type() const { return node_type; }
};

// Variable node (for ID references)

class VarNode : public ExprNode {
private:
    string name;
    ExprNode* index; // For array access, nullptr for simple variables

public:
    VarNode(string name, string type, ExprNode* idx = nullptr)
        : ExprNode(type), name(name), index(idx) {}
    
    ~VarNode() { if(index) delete index; }
    
    bool has_index() const { return index != nullptr; }
    
    string generate_index_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                              int& temp_count, int& label_count) const {
        return index->generate_code(outcode, symbol_to_temp, temp_count, label_count);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        if (!index) {
            auto found = symbol_to_temp.find(name);
            if (found != symbol_to_temp.end()) {
                string cached_value = found->second;
                size_t marker_position = cached_value.find('|');
                string value = cached_value.substr(0, marker_position);
                string marker = marker_position == string::npos ? "" : cached_value.substr(marker_position + 1);
                if (marker == "parameter" || marker == "assigned") {
                    symbol_to_temp[name] = value + "|cached";
                    return value;
                }
                temp_count++;
                return value;
            }
        }
        string result = "t" + to_string(temp_count++);
        if (index) {
            string index_value = generate_index_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << result << " = " << name << "[" << index_value << "]" << endl;
        } else {
            outcode << result << " = " << name << endl;
        }
        if (!index) symbol_to_temp[name] = result + "|cached";
        return result;
    }
    
    string get_name() const { return name; }
};

// Constant node

class ConstNode : public ExprNode {
private:
    string value;

public:
    ConstNode(string val, string type) : ExprNode(type), value(val) {}
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string result = "t" + to_string(temp_count++);
        outcode << result << " = " << value << endl;
        return result;
    }
};

// Binary operation node

class BinaryOpNode : public ExprNode {
private:
    string op;
    ExprNode* left;
    ExprNode* right;

public:
    BinaryOpNode(string op, ExprNode* left, ExprNode* right, string result_type)
        : ExprNode(result_type), op(op), left(left), right(right) {}
    
    ~BinaryOpNode() {
        delete left;
        delete right;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string left_value = left->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        string right_value = right->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        string result = "t" + to_string(temp_count++);
        outcode << result << " = " << left_value << " " << op << " " << right_value << endl;
        return result;
    }
};

// Unary operation node

class UnaryOpNode : public ExprNode {
private:
    string op;
    ExprNode* expr;

public:
    UnaryOpNode(string op, ExprNode* expr, string result_type)
        : ExprNode(result_type), op(op), expr(expr) {}
    
    ~UnaryOpNode() { delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string value = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        string result = "t" + to_string(temp_count++);
        if (op == "+") outcode << result << " = " << value << endl;
        else outcode << result << " = " << op << value << endl;
        return result;
    }
};

// Assignment node

class AssignNode : public ExprNode {
private:
    VarNode* lhs;
    ExprNode* rhs;

public:
    AssignNode(VarNode* lhs, ExprNode* rhs, string result_type)
        : ExprNode(result_type), lhs(lhs), rhs(rhs) {}
    
    ~AssignNode() {
        delete lhs;
        delete rhs;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string value = rhs->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        if (lhs->has_index()) {
            string index_value = lhs->generate_index_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << lhs->get_name() << "[" << index_value << "] = " << value << endl;
        } else {
            outcode << lhs->get_name() << " = " << value << endl;
        }
        if (!lhs->has_index() && symbol_to_temp.find(lhs->get_name()) != symbol_to_temp.end()) {
            symbol_to_temp[lhs->get_name()] = value + "|assigned";
        }
        return value;
    }
};

// Statement node types

class StmtNode : public ASTNode {
public:
    virtual string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                                int& temp_count, int& label_count) const = 0;
};

// Expression statement node

class ExprStmtNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ExprStmtNode(ExprNode* e) : expr(e) {}
    ~ExprStmtNode() { if(expr) delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        if (expr) return expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        return "";
    }
};

// Block (compound statement) node

class BlockNode : public StmtNode {
private:
    vector<StmtNode*> statements;

public:
    ~BlockNode() {
        for (auto stmt : statements) {
            delete stmt;
        }
    }
    
    void add_statement(StmtNode* stmt) {
        if (stmt) statements.push_back(stmt);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        for (auto stmt : statements) {
            if (stmt) stmt->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return "";
    }
};

// If statement node

class IfNode : public StmtNode {
private:
    ExprNode* condition;
    StmtNode* then_block;
    StmtNode* else_block; // nullptr if no else part

public:
    IfNode(ExprNode* cond, StmtNode* then_stmt, StmtNode* else_stmt = nullptr)
        : condition(cond), then_block(then_stmt), else_block(else_stmt) {}
    
    ~IfNode() {
        delete condition;
        delete then_block;
        if (else_block) delete else_block;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string condition_value = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        string true_label = "L" + to_string(label_count++);
        string false_label = "L" + to_string(label_count++);
        string end_label = "";
        if (!else_block) end_label = "L" + to_string(label_count++);
        outcode << "if " << condition_value << " goto " << true_label << endl;
        outcode << "goto " << false_label << endl;
        outcode << true_label << ":" << endl;
        then_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        if (else_block) {
            end_label = "L" + to_string(label_count++);
            outcode << "goto " << end_label << endl;
            outcode << false_label << ":" << endl;
            else_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << end_label << ":" << endl;
        } else {
            outcode << "goto " << end_label << endl;
            outcode << false_label << ":" << endl;
            outcode << end_label << ":" << endl;
        }
        return "";
    }
};

// While statement node

class WhileNode : public StmtNode {
private:
    ExprNode* condition;
    StmtNode* body;

public:
    WhileNode(ExprNode* cond, StmtNode* body_stmt)
        : condition(cond), body(body_stmt) {}
    
    ~WhileNode() {
        delete condition;
        delete body;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        for (auto& entry : symbol_to_temp) {
            size_t marker_position = entry.second.find('|');
            if (marker_position != string::npos && entry.second.substr(marker_position + 1) == "assigned") {
                entry.second = entry.second.substr(0, marker_position) + "|cached";
            }
        }
        string start_label = "L" + to_string(label_count++);
        string body_label = "L" + to_string(label_count++);
        string end_label = "L" + to_string(label_count++);
        outcode << start_label << ":" << endl;
        temp_count++;
        string condition_value = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "if " << condition_value << " goto " << body_label << endl;
        outcode << "goto " << end_label << endl;
        outcode << body_label << ":" << endl;
        body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "goto " << start_label << endl;
        outcode << end_label << ":" << endl;
        return "";
    }
};

// For statement node

class ForNode : public StmtNode {
private:
    ExprNode* init;
    ExprNode* condition;
    ExprNode* update;
    StmtNode* body;

public:
    ForNode(ExprNode* init_expr, ExprNode* cond_expr, ExprNode* update_expr, StmtNode* body_stmt)
        : init(init_expr), condition(cond_expr), update(update_expr), body(body_stmt) {}
    
    ~ForNode() {
        if (init) delete init;
        if (condition) delete condition;
        if (update) delete update;
        delete body;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        if (init) init->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        string start_label = "L" + to_string(label_count++);
        string body_label = "L" + to_string(label_count++);
        string end_label = "L" + to_string(label_count++);
        outcode << start_label << ":" << endl;
        if (condition) {
            string condition_value = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "if " << condition_value << " goto " << body_label << endl;
            outcode << "goto " << end_label << endl;
        } else {
            outcode << "goto " << body_label << endl;
        }
        outcode << body_label << ":" << endl;
        if (body) body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        if (update) update->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "goto " << start_label << endl;
        outcode << end_label << ":" << endl;
        return "";
    }
};

// Return statement node

class ReturnNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ReturnNode(ExprNode* e) : expr(e) {}
    ~ReturnNode() { if (expr) delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        if (expr) {
            string value = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "return " << value << endl;
        } else {
            outcode << "return" << endl;
        }
        return "";
    }
};

// Declaration node

class DeclNode : public StmtNode {
private:
    string type;
    vector<pair<string, int>> vars; // Variable name and array size (0 for regular vars)

public:
    DeclNode(string t) : type(t) {}
    
    void add_var(string name, int array_size = 0) {
        vars.push_back(make_pair(name, array_size));
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        for (const auto& var : vars) {
            outcode << "// Declaration: " << type << " " << var.first;
            if (var.second > 0) outcode << "[" << var.second << "]";
            outcode << endl;
        }
        return "";
    }
    
    string get_type() const { return type; }
    const vector<pair<string, int>>& get_vars() const { return vars; }
};

// Function declaration node

class FuncDeclNode : public ASTNode {
private:
    string return_type;
    string name;
    vector<pair<string, string>> params; // Parameter type and name
    BlockNode* body;

public:
    FuncDeclNode(string ret_type, string n) : return_type(ret_type), name(n), body(nullptr) {}
    ~FuncDeclNode() { if (body) delete body; }
    
    void add_param(string type, string name) {
        params.push_back(make_pair(type, name));
    }
    
    void set_body(BlockNode* b) {
        body = b;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        outcode << "// Function: " << return_type << " " << name << "(";
        for (size_t i = 0; i < params.size(); i++) {
            if (i > 0) outcode << ", ";
            outcode << params[i].first << " " << params[i].second;
        }
        outcode << ")" << endl;
        for (const auto& param : params) {
            string value = "t" + to_string(temp_count++);
            outcode << value << " = " << param.second << endl;
            symbol_to_temp[param.second] = value + "|parameter";
        }
        if (body) body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        for (const auto& param : params) {
            symbol_to_temp.erase(param.second);
        }
        outcode << endl;
        return "";
    }
};

// Helper class for function arguments

class ArgumentsNode : public ASTNode {
private:
    vector<ExprNode*> args;

public:
    ~ArgumentsNode() {
        // Don't delete args here - they'll be transferred to FuncCallNode
    }
    
    void add_argument(ExprNode* arg) {
        if (arg) args.push_back(arg);
    }
    
    ExprNode* get_argument(int index) const {
        if (index >= 0 && index < args.size()) {
            return args[index];
        }
        return nullptr;
    }
    
    size_t size() const {
        return args.size();
    }
    
    const vector<ExprNode*>& get_arguments() const {
        return args;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // This node doesn't generate code directly
        return "";
    }
};

// Function call node

class FuncCallNode : public ExprNode {
private:
    string func_name;
    vector<ExprNode*> arguments;

public:
    FuncCallNode(string name, string result_type)
        : ExprNode(result_type), func_name(name) {}
    
    ~FuncCallNode() {
        for (auto arg : arguments) {
            delete arg;
        }
    }
    
    void add_argument(ExprNode* arg) {
        if (arg) arguments.push_back(arg);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        for (auto arg : arguments) {
            string value = arg->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "param " << value << endl;
        }
        string result = "t" + to_string(temp_count++);
        outcode << result << " = call " << func_name << ", " << arguments.size() << endl;
        return result;
    }
};

// Program node (root of AST)

class ProgramNode : public ASTNode {
private:
    vector<ASTNode*> units;

public:
    ~ProgramNode() {
        for (auto unit : units) {
            delete unit;
        }
    }
    
    void add_unit(ASTNode* unit) {
        if (unit) units.push_back(unit);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        for (auto unit : units) {
            if (unit) unit->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return "";
    }
};

#endif // AST_H