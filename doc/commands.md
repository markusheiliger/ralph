# Ralph CLI - Command 

The Ralph CLI (throughout this doc just called CLI) follows the following pattern when it commes to passed in arguments:

- Running the CLI in default mode (see [Default Mode](##default-mode))

  ```
  ralph /path [--options]
  ```

- Running a CLI in subcommand mode (see [Subcommand Mode](#subcommand-mode))

  ```
  ralph --subcommand [--options]

## Default Mode

When running the in subcommand mode, the CLI expects the first argument passed in to be a path information. This path can be absolute or relative to the current working directory, and needs to be resolved and validated based on the following rules (the resolved path is called target path throughout this chapter):

1) The target path MUST point to a directory and the directory MUST exist.
2) The target path MUST point to a directory that represents a git repository or is located underneath a directory that represents a git repository.

If one of the conditions is NOT met the script bails out with an error! In case the the target path points to a directory that is located underneath a directory that represents a git repository the target path is replaced with the path to the directory that represents the git repository's root.

The target path directory must contain a sub directory called **.ralph** with the following files in it:

- story.md

  This file contains the story to process. Beside information like Title and State of the story the file should contain the user story itself, but also the acceptance criterias that need to be fulfilled before the story can be processed. To increate efficiency, you can create multiple story files if needed following the file naming pattern **story-[epoch].md** (for simplicity the CLI provides the --story option in default mode to create new story files).

- common.md

  This file contains common information valid for each story to apply. While its content defines the baseline for the story.md processing, it is possible to overrule in the story.md. 

Once the CLI processed its first story you will find another directory under **.ralph** called **history**. This folder keeps the already processed story files. Means, when a story file was successfully processed, the story file is moved to the history folder. To keep processed stories in cronological order, the story file is renamed to [timestamp]-[storytitle].md in the history directory (timestamp >> date +%Y%m%d-%H%M%S).

### Stories

To enforce a minimum level of standardization each story file comes with a YAML header described below.

```
---
title: The title of your story
state: [draft|feedback|complete]
---
```

While the purpose of the **title** field is self-explaining, the **state** field need some more explaination as it affects the way how the CLI handles this story. As a groundrule: If the story file doesn't contain a YAML header, no state field is provided, or the state field contains an unknown value, the resolve state is always **draft**

| Value | Action |
|:------|:-------|
| draft | The story file will be ignored by the CLI. Stories in **draft** state are work in progress! |
| feedback | The story is processed but must not affect any other file in the repository that the story file itself by appending a / updating the feedback paragraph in the story file. |
| complete | The story is ready to be processed by the CLI. |

### Options

- --story

  Create a new story file in the **.ralph** folder. If no story.md file exists, create a new story.md file. If exists, create a file called story-[epoch].md (epoch >> date +%s%3N). In both cases the new story file is initialized with the YAML header described in this document.

- --init

  Initializes the current by target directory by adding the .ralph folder including content. 

## Subcommand Mode

