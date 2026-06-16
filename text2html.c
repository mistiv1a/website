#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

// Check if a line is empty (contains only whitespace characters)
int is_empty_line(const char *line) {
    while (*line) {
        if (!isspace((unsigned char)*line)) {
            return 0; // Found a non-whitespace character, not an empty line
        }
        line++;
    }
    return 1;
}

// Remove trailing newline characters from a string
void strip_newline(char *str) {
    size_t len = strlen(str);
    while (len > 0 && (str[len - 1] == '\n' || str[len - 1] == '\r')) {
        str[len - 1] = '\0';
        len--;
    }
}

// Print string with HTML escaping to prevent <, >, &, etc., from breaking the HTML structure
void print_escaped(FILE *out, const char *str, size_t len) {
    for (size_t i = 0; i < len; i++) {
        if (str[i] == '<') fprintf(out, "&lt;");
        else if (str[i] == '>') fprintf(out, "&gt;");
        else if (str[i] == '&') fprintf(out, "&amp;");
        else if (str[i] == '"') fprintf(out, "&quot;");
        else fputc(str[i], out);
    }
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: %s <input.txt> <output.html>\n", argv[0]);
        return 1;
    }

    FILE *in = fopen(argv[1], "r");
    if (!in) {
        perror("Cannot open input file");
        return 1;
    }

    FILE *out = fopen(argv[2], "w");
    if (!out) {
        perror("Cannot create output file");
        fclose(in);
        return 1;
    }

    char line[4096];
    char title[4096] = "Untitled"; // Use a default title if no suitable title is found

    // ---------------------------------------------------------
    // First pass: Find the title (first non-empty line without "[[")
    // ---------------------------------------------------------
    while (fgets(line, sizeof(line), in)) {
        if (!is_empty_line(line) && strstr(line, "[[") == NULL) {
            strcpy(title, line);
            strip_newline(title);
            break; // Break immediately after finding the title
        }
    }

    // Reset file pointer to the beginning for content conversion
    rewind(in);

    // ---------------------------------------------------------
    // Second pass: Generate HTML and parse [[...]]
    // ---------------------------------------------------------
    
    // Write HTML header (Note: '%' in printf needs to be escaped as '%%')
    fprintf(out, "<!DOCTYPE html>\n<html>\n<head>\n<title>");
    print_escaped(out, title, strlen(title)); // Escape the title
    fprintf(out, "</title>\n<style>body { zoom: 150%%; }</style>\n</head>\n<body>\n<pre>");

    // Read line by line and process links
    while (fgets(line, sizeof(line), in)) {
        char *start = line;
        char *link_start;

        // Check if "[[" exists in the current string segment
        while ((link_start = strstr(start, "[[")) != NULL) {
            char *link_end = strstr(link_start + 2, "]]");
            
            if (link_end) { // If a matching "]]" is successfully found
                // 1. Print the normal text before "[["
                print_escaped(out, start, link_start - start);

                // 2. Extract the content between "[[" and "]]"
                size_t link_len = link_end - (link_start + 2);
                char link_text[4096] = {0};
                strncpy(link_text, link_start + 2, link_len);

                // 3. Print the HTML hyperlink tag
                fprintf(out, "<a href=\"");
                print_escaped(out, link_text, link_len); // href attribute
                fprintf(out, "\">");
                print_escaped(out, link_text, link_len); // Link display text
                fprintf(out, "</a>");

                // Move the start pointer to after "]]"
                start = link_end + 2;
            } else {
                // If there is "[[" without a matching "]]", treat it as normal text and break
                break;
            }
        }
        
        // Print the remaining normal text of the line (including newline)
        print_escaped(out, start, strlen(start));
    }

    // Write HTML footer
    fprintf(out, "\n\n-----\nEmail: i (at) mistivia (dot) com</pre>\n</body>\n</html>\n");

    fclose(in);
    fclose(out);
    
    return 0;
}
