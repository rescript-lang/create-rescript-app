import { exec as execCallback } from "child_process";
import { promisify } from "util";

export const exec = promisify(execCallback);
